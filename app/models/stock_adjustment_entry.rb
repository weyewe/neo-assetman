class StockAdjustmentEntry < ActiveRecord::Base
  has_one :stock_mutation,  :as => :stock_mutation_source
  # 1 stock mutation to deduct pending_receival
  # 1 stock mutation to add ready 
  belongs_to :stock_adjustment
  belongs_to :item 
  
  
  validates_presence_of :stock_adjustment_id , :item_id, :valid_actual_quantity
  
  validate :valid_stock_adjustment_id
  validate :valid_actual_quantity
  validate :valid_item_id
  validate :uniq_item_id 
  
  def all_fields_present?
    stock_adjustment_id.present? and
    item_id.present? and 
    actual_quantity.present? 
  end
  
  def valid_stock_adjustment_id
    return if not self.all_fields_present? 
    
    begin
       StockAdjustment.find stock_adjustment_id   
    rescue
      self.errors.add(:stock_adjustment_id, "Harus memilih dokumen penyesuaian ") 
      return self 
    end
  end
     
  def valid_actual_quantity
    return if not all_fields_present? 
    
    begin
      if actual_quantity < 0 
        self.errors.add(:actual_quantity , "Kuantitas aktual tidak boleh lebih kecil dari 0")
        return self 
      end
      
      quantity_initial = warehouse_item.ready 
      quantity_diff = self.actual_quantity - quantity_initial
      
      if not self.is_confirmed? and quantity_diff == 0 
        msg = "Kuantitas sekarang sama seperti kuantitas awal (#{quantity_initial}) " + 
              " di gudang ini : #{warehouse_item.warehouse.name}"
        self.errors.add(:actual_quantity, msg)
        return self 
      end

    rescue
      self.errors.add(:item_id, "Item tidak valid")
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

  def warehouse_item
    begin
      return WarehouseItem.find_or_create_object(
        :warehouse_id => self.stock_adjustment.warehouse_id, 
        :item_id => self.item_id 
      )
    rescue
      return nil 
    end
  end
 
  
  def uniq_item_id
    return if not all_fields_present?
    
    begin
      
      parent = self.stock_adjustment
      stock_adjustment_entry_count = StockAdjustmentEntry.where(
        :item_id => self.item_id,
        :stock_adjustment_id => parent.id  
      ).count 

      stock_adjustment = self.stock_adjustment
      msg = "Item #{item.name} sudah terdaftar di penyesuaian ini."

      if not self.persisted? and stock_adjustment_entry_count != 0
        errors.add(:item_id , msg ) 
      elsif self.persisted? and not self.item_id_changed? and stock_adjustment_entry_count > 1 
        errors.add(:item_id , msg ) 
      elsif self.persisted? and  self.item_id_changed? and stock_adjustment_entry_count  != 0 
        errors.add(:item_id , msg )
      end
    rescue
    end
  end
  
   
  
  
   
  def self.create_object( params ) 
    new_object = self.new
    new_object.item_id = params[:item_id]
    new_object.stock_adjustment_id = params[:stock_adjustment_id]
    new_object.actual_quantity = params[:actual_quantity]
    
   
    new_object.save  
    
    return new_object
  end
  
  def update_object( params ) 
    if self.is_confirmed? 
      self.errors.add(:generic_errors, "Sudah konfirmasi, tidak bisa update")
      return self 
    end
    
    self.item_id = params[:item_id]
    self.stock_adjustment_id = params[:stock_adjustment_id]
    self.actual_quantity = params[:actual_quantity]
    
     
    
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
    self.valid_actual_quantity  
   
    if self.errors.size != 0 
      self.errors.add(:generic_errors, self.errors.messages[:actual_quantity].first)
      return false
    end
    
    return true 
  end
  
  def confirm
    return if self.is_confirmed? 
    
    self.initial_quantity = warehouse_item.ready 
    self.diff = self.actual_quantity - self.initial_quantity
    
    self.is_confirmed = true 
    self.confirmed_at = DateTime.now 
    if self.save 
      StockMutation.create_stock_adjustment_mutation( self ) 
    end
  end
  
  
  def warehouse_item
    WarehouseItem.find_or_create_object( 
      :warehouse_id => self.purchase_order_entry.purchase_order.warehouse_id , 
      :item_id => self.purchase_order_entry.item_id 
    )
  end
 
   
=begin
  effect of purchase return confirm: received deduct , pending_receival add
  effect of purchase return unconfirm: received add, pending_receival negative 
=end
  def can_be_unconfirmed?
    reverse_adjustment_quantity = -1*diff  
    
    wh_item = self.warehouse_item
    item = self.item 
    
    final_item_ready = item.ready + reverse_adjustment_quantity
    final_wh_item_ready = wh_item.ready + reverse_adjustment_quantity
    
    if final_item_ready < 0 or final_wh_item_ready < 0 
      msg = "Akan menyebabkan jumlah item ready menjadi : #{final_item_ready}."
      self.errors.add(:generic_errors, msg )
      return false
    end
  
    return true 
  end
  
  
  def unconfirm
    return if not self.is_confirmed? 
    
    return self if not self.can_be_unconfirmed? 
    
    
    self.stock_mutation.delete_object  
    self.is_confirmed = false
    self.save
  end
end
