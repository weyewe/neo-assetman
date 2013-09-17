class StockAdjustment < ActiveRecord::Base
  has_one :stock_mutation,  :as => :stock_mutation_source
  belongs_to :warehouse
  belongs_to :item 
  belongs_to :warehouse_item 
  
  validates_presence_of :warehouse_id, :item_id 
  
  validate :valid_warehouse_id
  validate :valid_item_id 
  validate :valid_actual_quantity 
  # validate :non_zero_diff 
  
  
  
  def all_fields_present?
    self.warehouse_id.present? and 
    self.item_id.present? and 
    self.actual_quantity.present? 
  end
  
  def valid_actual_quantity
    return if not all_fields_present? 
    if actual_quantity < 0 
      self.errors.add(:actual_quantity , "Kuantitas aktual tidak boleh lebih kecil dari 0")
      return self 
    end
  end
  
  def valid_warehouse_id
    return if not self.all_fields_present? 
    
    begin
       Warehouse.find warehouse_id   
    rescue
      self.errors.add(:warehouse_id, "Harus memilih gudang") 
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
  
  def non_zero_diff?
    return if not self.all_fields_present?
    return if self.is_confirmed?  
    
    begin
      quantity_initial = warehouse_item.ready 
      quantity_diff = self.actual_quantity - quantity_initial


      return quantity_diff == 0
      # if quantity_diff == 0 
      #   return false
      #   self.errors.add(:actual_quantity , "Sama seperti quantity yang sudah ada")
      #   return self 
      # end
    rescue 
      return false 
    end
  end
  
  def assign_warehouse_item
    warehouse_item = WarehouseItem.find_or_create_object(:item_id => item_id, :warehouse_id => warehouse_id) 
    self.warehouse_item_id = warehouse_item.id 
    self.save 
  end
  
  def self.create_object( params ) 
    new_object = self.new
    new_object.item_id = params[:item_id]
    new_object.warehouse_id = params[:warehouse_id]
    new_object.actual_quantity = params[:actual_quantity]
    
    if new_object.non_zero_diff?
      self.errors.add(:actual_quantity , "Sama seperti quantity yang sudah ada")
      return self 
    end
    
    if new_object.save 
      new_object.assign_warehouse_item  
    end
    return new_object 
  end
  
  def update_object( params ) 
    if self.is_confirmed? 
      self.errors.add(:generic_errors, "Sudah konfirmasi, tidak bisa update")
      return self 
    end
    
    self.item_id = params[:item_id]
    self.warehouse_id = params[:warehouse_id]
    self.actual_quantity = params[:actual_quantity]
    
    
    if self.non_zero_diff?
      self.errors.add(:actual_quantity , "Sama seperti quantity yang sudah ada")
      return self 
    end
    
    if self.save 
      self.assign_warehouse_item 
    end
    return self 
  end
  
  def delete_object
    if self.is_confirmed?
      self.errors.add(:generic_errors, "Sudah konfirmasi. Tidak bisa delete")
      return self 
    end
    
    self.destroy 
  end
  
  def confirm
    return if self.is_confirmed?
    
    self.initial_quantity = warehouse_item.ready 
    self.diff = self.actual_quantity - self.initial_quantity 
    self.is_confirmed = true 
    self.confirmed_at = DateTime.now 
    if self.save 
      StockMutation.create_stock_adjustment_mutation( self )  # will update the item.ready and warehouse_item.ready 
    end
  end
  
  def unconfirm
    return if not self.is_confirmed? 
    
    reverse_adjustment_quantity = -1*diff 
    # puts "initial item ready : #{item.ready}" 
    # puts "initial wh_item ready: #{warehouse_item.ready}"
    
    # puts "reverse adjusemtnet: #{ reverse_adjustment_quantity}"
    final_item_quantity = item.ready  + reverse_adjustment_quantity
    final_warehouse_item_quantity = warehouse_item.ready  + reverse_adjustment_quantity
    
    if final_item_quantity < 0 or final_warehouse_item_quantity < 0 
      msg = "Tidak bisa unconfirm karena akan menyebabkan jumlah item menjadi #{final_item_quantity} " + 
                " dan jumlah item gudang menjadi :#{final_warehouse_item_quantity}"
      self.errors.add(:generic_errors, msg )
      return self 
    end
    
    
    self.stock_mutation.delete_object
    
    self.is_confirmed = false 
    self.save 
    
  end
end
