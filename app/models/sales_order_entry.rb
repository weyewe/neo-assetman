class SalesOrderEntry < ActiveRecord::Base
  has_one :stock_mutation,  :as => :stock_mutation_source
  belongs_to :sales_order 
  belongs_to :item 
  
  has_many :sales_delivery_entries
  has_many :sales_return_entries 
  
  # has_many :sales_receival_entries
  
  validates_presence_of :quantity, :sales_order_id, :item_id 
  
  validate :valid_quantity
  validate :valid_item_id
  validate :valid_sales_order_id 
  validate :unique_sales_order_entry_item_id

  
  def all_fields_present?
    quantity.present? and 
    sales_order_id.present? and
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
  
  def unique_sales_order_entry_item_id
    return if not all_fields_present?
    
    begin
      
      parent = self.sales_order
      sales_order_entry_count = SalesOrderEntry.where(
        :item_id => self.item_id,
        :sales_order_id => parent.id  
      ).count 

      item = self.item 
      sales_order = self.sales_order
      msg = "Item #{item.name} dari pemesanan #{sales_order.code} sudah terdaftar di pembelian ini"

      if not self.persisted? and sales_order_entry_count != 0
        errors.add(:item_id , msg ) 
      elsif self.persisted? and not self.item_id_changed? and sales_order_entry_count > 1 
        errors.add(:item_id , msg ) 
      elsif self.persisted? and  self.item_id_changed? and sales_order_entry_count  != 0 
        errors.add(:item_id , msg )
      end
    rescue
    end
  end
  
  def valid_sales_order_id
    return if not self.all_fields_present? 
    
    begin
       so = SalesOrder.find sales_order_id   
       if not self.persisted? and so.is_confirmed? 
         self.errors.add(:sales_order_id, "SO sudah di konfirmasi. tidak bisa menambah item")
         return self 
       end
    rescue
      self.errors.add(:sales_order_id, "Harus memilih SO") 
      return self 
    end
  end
  
  def self.create_object( params ) 
    new_object = self.new 
    new_object.quantity          = params[:quantity]
    new_object.sales_order_id = params[:sales_order_id]
    new_object.item_id           = params[:item_id]
    
    if new_object.save 
      new_object.pending_delivery = new_object.quantity
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
    self.sales_order_id = params[:sales_order_id]
    self.item_id           = params[:item_id]
    
    if self.save 
      self.pending_delivery = self.quantity
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
      StockMutation.create_sales_order_entry_stock_mutation( self ) 
    end
  end
   
  
  def can_be_unconfirmed?
    
    if self.sales_delivery_entries.count != 0
      self.errors.add(:generic_errors, "Tidak bisa unconfirm karena sudah ada penerimaan barang")
      return false 
    end
    
    if self.sales_return_entries.count != 0
      self.errors.add(:generic_errors, "Tidak bisa unconfirm karena sudah ada penerimaan barang")
      return false 
    end

    
    # puts "inside @can_be_unconfirmed? => item.pending_delivery : #{item.pending_delivery}"  
      
    reverse_adjustment_quantity = -1*quantity  
    final_item_quantity = item.pending_delivery  + reverse_adjustment_quantity
    
    if final_item_quantity < 0  
      msg = "Tidak bisa unconfirm karena akan menyebabkan jumlah #{item.name} pending delivery menjadi #{final_item_quantity} "  
      self.errors.add(:generic_errors, msg )
      return false 
    end
    
    return true 
  end
  
  def update_pending_delivery_and_delivered( diff )  
    self.pending_delivery -=  diff 
    self.delivered += diff 
    self.save
  end
  
  def unconfirm 
    return if not self.is_confirmed? 
    
    
    return self if not self.can_be_unconfirmed? 
    
    self.stock_mutation.delete_object 
    self.is_confirmed = false
    self.save 
  end
  
  
  
end
