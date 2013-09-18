class PurchaseOrderEntry < ActiveRecord::Base
  has_one :stock_mutation,  :as => :stock_mutation_source
  belongs_to :purchase_order 
  belongs_to :item 
  
  has_many :purchase_receival_entries
  
  validates_presence_of :quantity, :purchase_order_id, :item_id 
  
  validate :valid_quantity
  validate :valid_item_id
  validate :valid_purchase_order_id 
  validate :unique_purchase_order_entry_item_id

  
  def all_fields_present?
    quantity.present? and 
    purchase_order_id.present? and
    item_id.present? 
  end
  
  def valid_quantity
    return if not all_fields_present?
    
    if quantity <= 0 
      self.errors.add(:quantity, "Tidak boleh lebih kecil atau sama dengan 0")
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
  
  def unique_purchase_order_entry_item_id
    return if not all_fields_present?
    
    begin
      
      parent = self.purchase_order
      purchase_order_entry_count = PurchaseOrderEntry.where(
        :item_id => self.item_id,
        :purchase_order_id => parent.id  
      ).count 

      item = self.item 
      purchase_order = self.purchase_order
      msg = "Item #{item.name} dari pemesanan #{purchase_order.code} sudah terdaftar di pembelian ini"

      if not self.persisted? and purchase_order_entry_count != 0
        errors.add(:item_id , msg ) 
      elsif self.persisted? and not self.item_id_changed? and purchase_order_entry_count > 1 
        errors.add(:item_id , msg ) 
      elsif self.persisted? and  self.item_id_changed? and purchase_order_entry_count  != 0 
        errors.add(:item_id , msg )
      end
    rescue
    end
  end
  
  def valid_purchase_order_id
    return if not self.all_fields_present? 
    
    begin
       po = PurchaseOrder.find purchase_order_id   
       if po.is_confirmed? 
         self.errors.add(:purchase_order_id, "PO sudah di konfirmasi. tidak bisa menambah item")
         return self 
       end
    rescue
      self.errors.add(:purchase_order_id, "Harus memilih PO") 
      return self 
    end
  end
  
  def self.create_object( params ) 
    new_object = self.new 
    new_object.quantity          = params[:quantity]
    new_object.purchase_order_id = params[:purchase_order_id]
    new_object.item_id           = params[:item_id]
    
    if new_object.save 
      new_object.pending_receival = new_object.quantity
      new_object.save 
    end
    return new_object
  end
  
  def update_object( params ) 
    if self.is_confirmed?
      self.errors.add(:generic_errors, "Sudah dikonfirmasi")
      return self 
    end
    self.quantity          = params[:quantity]
    self.purchase_order_id = params[:purchase_order_id]
    self.item_id           = params[:item_id]
    
    if self.save 
      self.pending_receival = self.quantity
      self.save 
    end
    return self 
  end
  
  def delete_object 
    if self.is_confirmed?
      self.errors.add(:generic_errors, "Sudah dikonfirmasi")
      return self 
    end
    

    
    self.destroy 
  end
  
  def confirm
    return if self.is_confirmed? 
    
    self.is_confirmed = true 
    self.confirmed_at = DateTime.now 
    if self.save 
      StockMutation.create_purchase_order_entry_stock_mutation( self ) 
    end
  end
  
  def warehouse_item
    WarehouseItem.find_or_create_object( 
      :warehouse_id => self.purchase_order.warehouse_id , 
      :item_id => self.item_id 
    )
  end
  
  # def pending_receival
  #   quantity - received
  # end
  
  def can_be_unconfirmed?
    reverse_adjustment_quantity = -1*quantity  
    
    # puts "initial item.pending_receival: #{item.pending_receival}"
    # puts "the reverse adjusetment: #{reverse_adjustment_quantity}"
    final_item_quantity = item.pending_receival  + reverse_adjustment_quantity
    final_warehouse_item_quantity = warehouse_item.pending_receival  + reverse_adjustment_quantity
    
    if final_item_quantity < 0 or final_warehouse_item_quantity < 0 
      msg = "Tidak bisa unconfirm karena akan menyebabkan jumlah #{item.name} pending receival menjadi #{final_item_quantity} " + 
                " dan jumlah item gudang menjadi :#{final_warehouse_item_quantity}"
      self.errors.add(:generic_errors, msg )
      return false 
    end
    
    return true 
  end
  
  def update_pending_receival( diff ) 
    self.pending_receival +=  diff 
    self.save
  end
  
  def unconfirm 
    # puts "Gonna unconfirm poe"
    return if not self.is_confirmed? 
    
    if self.purchase_receival_entries.count != 0
      self.errors.add(:generic_errors, "Tidak bisa unconfirm karena sudah ada penerimaan barang")
      return self 
    end
    
    # puts "it is confirmed, hence will move forward"
    return self if not self.can_be_unconfirmed? 
    
    # puts "can be unconfirmed"
    
    self.stock_mutation.delete_object 
    self.is_confirmed = false
    self.save 
  end
  
  
  
end
