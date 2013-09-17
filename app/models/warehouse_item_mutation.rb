class WarehouseItemMutation < ActiveRecord::Base
  has_many :stock_mutations,  :as => :stock_mutation_source
  belongs_to :item 
  
  
  validates_presence_of :item_id, 
                        :source_warehouse_id, 
                        :target_warehouse_id,
                        :quantity 
                        
  validate :valid_quantity
  validate :valid_source_and_target_warehouse_id 
  validate :valid_item 
  
  def valid_quantity 
    if quantity <= 0 
      self.errors.add(:quantity, "Harus lebih besar dari 0 ")
    end
  end
  
  
  def valid_item
    return if not all_fields_present? 
    
    begin
       Item.find item_id   
    rescue
      self.errors.add(:item_id, "Harus memilih item") 
      return self 
    end
  end
  
  
  def valid_source_and_target_warehouse_id 
    return if not all_fields_present? 
    
    begin
       source = Warehouse.find source_warehouse_id   
       target = Warehouse.find target_warehouse_id 
    rescue
      msg = "Harus memilih gudang"
      self.errors.add(:source_warehouse_id, msg ) 
      self.errors.add(:target_warehouse_id, msg ) 
      return self 
    end
    
    if source.id == target.id 
      msg = "Source Warehouse tidak boleh sama dengan Target Warehouse"
      self.errors.add(:source_warehouse_id, msg) 
      self.errors.add(:target_warehouse_id, msg)
      return self 
    end
    
    source_warehouse_item = WarehouseItem.where(:item_id => item_id, :warehouse_id => source_warehouse_id).first 
    if not source_warehouse_item.nil?
      if source_warehouse_item.ready < quantity 
        self.errors.add(:quantity, "Tidak boleh lebih dari #{source_warehouse_item.ready}")
        return self 
      end
    else
      self.errors.add(:item_id, "Tidak ada item #{item.name} di gudang #{source.name}")
      return self 
    end
  end
                        
  def all_fields_present?
    item_id.present? and 
    source_warehouse_id.present?  and 
    target_warehouse_id.present? and 
    quantity.present? 
  end
  
  
  def self.create_object( params ) 
    new_object = self.new 
    new_object.source_warehouse_id = params[:source_warehouse_id]
    new_object.target_warehouse_id = params[:target_warehouse_id]
    new_object.item_id = params[:item_id]
    new_object.quantity = params[:quantity]
    
    new_object.save
    return new_object 
  end
  
  def update_object( params ) 
    if self.is_confirmed? 
      self.errors.add(:generic_errors, "Tidak bisa update setelah konfirmasi")
      return self 
    end
    
    self.source_warehouse_id = params[:source_warehouse_id]
    self.target_warehouse_id = params[:target_warehouse_id]
    self.item_id = params[:item_id]
    self.quantity = params[:quantity]
    self.save
    return self 
  end
  
  def delete_object
    if self.is_confirmed? 
      self.errors.add(:generic_errors, "Tidak bisa delete setelah konfirmasi")
      return self
    end
    
    self.destroy 
  end
  
  def confirm
    return if self.is_confirmed? 
    
    self.is_confirmed = true 
    self.confirmed_at = DateTime.now 
    if self.save 
      StockMutation.create_warehouse_item_mutation_stock_mutation( self )  # will update the item.ready and warehouse_item.ready 
    end
  end
  
  def source_warehouse
    Warehouse.find_by_id self.source_warehouse_id 
  end
  
  def target_warehouse
    Warehouse.find_by_id self.target_warehouse_id 
  end
  
  def target_warehouse_item
     WarehouseItem.find_or_create_object(
      :warehouse_id => self.target_warehouse_id , 
      :item_id => self.item_id 
    )
  end
  
  def source_warehouse_item
     WarehouseItem.find_or_create_object(
      :warehouse_id => self.source_warehouse_id , 
      :item_id => self.item_id 
    )
  end
  
  def unconfirm
    return if not self.is_confirmed? 
    
    reverse_adjustment_quantity = -1*self.quantity  
    
    final_target_warehouse_item_quantity = target_warehouse_item.ready  + reverse_adjustment_quantity
    
    if final_target_warehouse_item_quantity < 0 
      msg = "Tidak bisa unconfirm karena akan menyebabkan  " + 
            "jumlah item gudang #{self.target_warehouse.name} menjadi :#{final_target_warehouse_item_quantity}"
      self.errors.add(:generic_errors, msg )
      return self 
    end
    
    
    self.stock_mutations.each {|x| x.delete_object } 
    
    self.is_confirmed = false 
    self.save 
  end
  
  
                        
end
