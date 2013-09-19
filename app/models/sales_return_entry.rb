class SalesReturnEntry < ActiveRecord::Base
  has_many :stock_mutations,  :as => :stock_mutation_source
  # 1 stock mutation to deduct pending_receival
  # 1 stock mutation to add ready 
  belongs_to :sales_return
  belongs_to :sales_order_entry 
  
  
  validates_presence_of :sales_return_id , :sales_order_entry_id, :quantity
  
  validate :valid_sales_return_id
  validate :valid_sales_order_entry_id 
  validate :valid_quantity
  validate :uniq_sales_order_entry_id 
  validate :confirmed_sales_order_entry
  
  def all_fields_present?
    sales_return_id.present? and
    sales_order_entry_id.present? and 
    quantity.present? 
  end
  
  def valid_sales_return_id
    return if not self.all_fields_present? 
    
    begin
       SalesReturn.find sales_return_id   
    rescue
      self.errors.add(:sales_return_id, "Harus memilih dokumen pengembalian") 
      return self 
    end
  end
  
  def valid_sales_order_entry_id
    return if not self.all_fields_present? 
    
    begin
       soe = SalesOrderEntry.find sales_order_entry_id   
       if soe.sales_order.customer_id != self.sales_return.customer_id
         self.errors.add(:sales_order_entry_id, "Bukan pesanan #{sales_return.customer.name}")
         return self 
       end
    rescue
      self.errors.add(:sales_order_entry_id, "Harus memilih item dari sales order") 
      return self 
    end
  end
  
  def valid_quantity
    return if not all_fields_present?
    
    if quantity <= 0 or 
        ( not self.is_confirmed? and quantity > sales_order_entry.delivered)
      self.errors.add(:quantity, "Harus di antara 0 dan #{ sales_order_entry.delivered}")
    end
  end
  
  def uniq_sales_order_entry_id
    return if not all_fields_present?
    
    begin
      
      parent = self.sales_return
      sales_return_entry_count = SalesReturnEntry.where(
        :sales_order_entry_id => self.sales_order_entry_id,
        :sales_return_id => parent.id  
      ).count 

      sales_order_entry = self.sales_order_entry 
      sales_return = self.sales_return
      sales_order = sales_order_entry.sales_order 
      msg = "Item #{sales_order_entry.item.name} dari pemesanan #{sales_order.code} sudah terdaftar di pengembalian ini"

      if not self.persisted? and sales_return_entry_count != 0
        errors.add(:sales_order_entry_id , msg ) 
      elsif self.persisted? and not self.sales_order_entry_id_changed? and sales_return_entry_count > 1 
        errors.add(:sales_order_entry_id , msg ) 
      elsif self.persisted? and  self.sales_order_entry_id_changed? and sales_return_entry_count  != 0 
        errors.add(:sales_order_entry_id , msg )
      end
    rescue
    end
  end
  
  def confirmed_sales_order_entry
    return if not all_fields_present? 
    
    if not sales_order_entry.is_confirmed? 
      self.errors.add(:sales_order_entry_id, "Belum di konfirmasi")
      return self 
    end
  end
  
  
  def self.create_object( params ) 
    new_object = self.new 
    new_object.sales_return_id = params[:sales_return_id]
    new_object.sales_order_entry_id = params[:sales_order_entry_id]
    new_object.quantity  = params[:quantity]
    
    new_object.save 
    return new_object
    
  end
  
  def update_object( params )
    if self.is_confirmed?
      self.errors.add(:generic_errors, "Sudah dikonfirmasi")
      return self 
    end
    self.sales_return_id = params[:sales_return_id]
    self.sales_order_entry_id = params[:sales_order_entry_id]
    self.quantity  = params[:quantity] 
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
      StockMutation.create_sales_return_entry_stock_mutations( self ) 
      sales_order_entry.update_pending_delivery_and_delivered( -1*self.quantity )
    end
  end
  
  
  def warehouse_item
    WarehouseItem.find_or_create_object( 
      :warehouse_id => self.sales_order_entry.sales_order.warehouse_id , 
      :item_id => self.sales_order_entry.item_id 
    )
  end
  
  def item
    Item.where(
      :id => self.sales_order_entry.item_id 
    ).first 
  end
   
   
=begin
  effect of sales return confirm: delivered deduct , pending_delivery add
  effect of sales return unconfirm: delivered add, pending_delivery negative 
=end
  def can_be_unconfirmed?
    reverse_adjustment_quantity = quantity  
    
    
    
    final_delivered = sales_order_entry.delivered  +  reverse_adjustment_quantity 
    if final_delivered  >  sales_order_entry.quantity 
      msg = "Tidak bisa unconfirm karena akan menyebabkan jumlah #{item.name}  yang dikirim menjadi "  + 
            " lebih dari yang dipesan: #{sales_order_entry.quantity }."
      self.errors.add(:generic_errors, msg )
      return false
    end
    
    return true 
  end
  
  
  def unconfirm
    return if not self.is_confirmed? 
    
    return self if not self.can_be_unconfirmed? 
    
    
    self.stock_mutations.each{|x| x.delete_object  }
    self.is_confirmed = false
    if self.save
      sales_order_entry.update_pending_delivery_and_delivered( self.quantity )
    end
  end
end
