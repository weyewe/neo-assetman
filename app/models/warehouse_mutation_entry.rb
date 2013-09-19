class WarehouseMutationEntry < ActiveRecord::Base
  has_many :stock_mutations,  :as => :stock_mutation_source
  # 1 stock mutation to deduct pending_receival
  # 1 stock mutation to add ready 
  belongs_to :warehouse_mutation
  belongs_to :item 
  
  
  validates_presence_of :warehouse_mutation_id , :item_id, :quantity
  
  validate :valid_warehouse_mutation_id
  validate :valid_quantity
  validate :valid_item_id
  validate :uniq_item_id 
  
  def all_fields_present?
    warehouse_mutation_id.present? and
    item_id.present? and 
    quantity.present? 
  end
  
  def valid_warehouse_mutation_id
    # puts "calling valid_warehouse_mutation_id"
    return if not self.all_fields_present? 
    
    begin
       WarehouseMutation.find warehouse_mutation_id   
    rescue
      self.errors.add(:warehouse_mutation_id, "Harus memilih dokumen mutasi gudang ") 
      return self 
    end
  end
  
  def source_warehouse_item
    return nil if warehouse_mutation.nil?
    begin
      WarehouseItem.find_or_create_object(
        :warehouse_id => warehouse_mutation.source_warehouse_id ,
        :item_id => item_id 
      )
    rescue
      return nil 
    end
  end
  
  def target_warehouse_item 
    return nil if warehouse_mutation.nil?
    begin
      WarehouseItem.find_or_create_object(
        :warehouse_id => warehouse_mutation.target_warehouse_id ,
        :item_id => item_id 
      )
    rescue
      return nil 
    end
  end
     
  def valid_quantity
    # puts "\ncalling valid actual quantity"
    return if not all_fields_present? 
    
    begin
      if quantity <= 0 
        self.errors.add(:quantity , "Kuantitas aktual tidak boleh lebih kecil dari 0")
        return self 
      end
      
      if source_warehouse_item.nil? 
        # puts "The warehouse item is nil"
        self.errors.add(:item_id, "Item invalid")
        return self
      end

      quantity_initial = source_warehouse_item.ready 
       

      # puts "The quantity_diff: #{quantity_diff}"

      if  not self.is_confirmed? and quantity > quantity_initial
        msg = "Kuantitas yang akan dipindahkan (#{quantity}) lebih banyak " + 
                " daripada kuantitas di gudang awal (#{quantity_initial})"  
        self.errors.add(:quantity, msg)
        return self 
      end
      
    rescue
      return self 
    end
    
  end 
  
  
  def valid_item_id
    return if not self.all_fields_present? 

    begin
      Item.find item_id  
    rescue
      self.errors.add(:item_id, "Harus memilih item") 
      return self 
    end
  end
 
  
  def uniq_item_id
    return if not all_fields_present?
    
    begin
      
      parent = self.warehouse_mutation
      warehouse_mutation_entry_count = WarehouseMutationEntry.where(
        :item_id => self.item_id,
        :warehouse_mutation_id => parent.id  
      ).count 

      warehouse_mutation = self.warehouse_mutation
      msg = "Item #{item.name} sudah terdaftar di penyesuaian ini."

      if not self.persisted? and warehouse_mutation_entry_count != 0
        errors.add(:item_id , msg ) 
      elsif self.persisted? and not self.item_id_changed? and warehouse_mutation_entry_count > 1 
        errors.add(:item_id , msg ) 
      elsif self.persisted? and  self.item_id_changed? and warehouse_mutation_entry_count  != 0 
        errors.add(:item_id , msg )
      end
    rescue
    end
  end
  
   
  
  
   
  def self.create_object( params ) 
    new_object = self.new
    new_object.item_id = params[:item_id]
    new_object.warehouse_mutation_id = params[:warehouse_mutation_id]
    new_object.quantity = params[:quantity]
    
    
    new_object.save  
    
    return new_object
  end
  
  def update_object( params ) 
    if self.is_confirmed? 
      self.errors.add(:generic_errors, "Sudah konfirmasi, tidak bisa update")
      return self 
    end
    
    self.item_id = params[:item_id]
    self.warehouse_mutation_id = params[:warehouse_mutation_id]
    self.quantity = params[:quantity]
    
     
    
    self.save  
    
    return self 
  end 
  
  def delete_object
    if self.is_confirmed?
      self.errors.add(:generic_errors, "Sudah dikonfirmasi")
      return self 
    end
    
    self.destroy 
  end
  
  def can_be_confirmed?
    self.valid_quantity  
   
    if self.errors.size != 0 
      self.errors.add(:generic_errors, self.errors.messages[:quantity].first)
      return false
    end
    
    return true 
  end
  
  def confirm
    return if self.is_confirmed? 
  
    
    self.is_confirmed = true 
    self.confirmed_at = DateTime.now 
    if self.save 
      StockMutation.create_warehouse_mutation_entry_stock_mutations( self ) 
    end
  end
  
   
 
   
=begin
  effect of purchase return confirm: received deduct , pending_receival add
  effect of purchase return unconfirm: received add, pending_receival negative 
=end
  def can_be_unconfirmed?
    reverse_adjustment_quantity = -1*quantity  
    
    target_wh_item =  self.target_warehouse_item
    
    final_target_wh_item_ready = target_wh_item.ready + reverse_adjustment_quantity
    
    if final_target_wh_item_ready < 0 
      msg = "Akan menyebabkan jumlah item ready di gudang #{target_wh_item.warehouse.name} " + 
            " menjadi : #{final_target_wh_item_ready}."
      self.errors.add(:generic_errors, msg )
      return false
    end
  
    return true 
  end
  
  
  def unconfirm
    return if not self.is_confirmed? 
    
    return self if not self.can_be_unconfirmed? 
    
    
    self.stock_mutations.each {|x| x.delete_object  }
    self.is_confirmed = false
    self.save
  end
end
