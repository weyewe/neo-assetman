class SalesDeliveryEntry < ActiveRecord::Base
  has_many :stock_mutations,  :as => :stock_mutation_source
  # 1 stock mutation to deduct pending_receival
  # 1 stock mutation to add ready 
  belongs_to :sales_delivery
  belongs_to :sales_order_entry 
  
  
  validates_presence_of :sales_delivery_id , :sales_order_entry_id, :quantity 
  
  validate :valid_sales_delivery_id
  validate :valid_sales_order_entry_id 
  validate :valid_quantity
  validate :uniq_sales_delivery_entry_id 
  validate :confirmed_sales_order_entry
  
  def all_fields_present?
    sales_delivery_id.present? and
    sales_order_entry_id.present? and 
    quantity.present? 
  end
  
  def valid_sales_delivery_id
    return if not self.all_fields_present? 
    
    begin
       SalesDelivery.find sales_delivery_id   
    rescue
      self.errors.add(:sales_delivery_id, "Harus memilih dokumen pengantaran") 
      return self 
    end
  end
  
  def valid_sales_order_entry_id
    return if not self.all_fields_present? 
    
    begin
       SalesOrderEntry.find sales_order_entry_id   
    rescue
      self.errors.add(:sales_order_entry_id, "Harus memilih item dari purchase order") 
      return self 
    end
  end
  
  def warehouse_item 
    begin
       item_id = self.sales_order_entry.item_id 
       warehouse_id = self.sales_delivery.warehouse_id
       WarehouseItem.find_or_create_object(
         :item_id => item_id,
         :warehouse_id => warehouse_id 
       )
    rescue
      return nil 
    end
  end
  
  def valid_quantity
    return if not all_fields_present?
    
    if quantity <= 0 or quantity > sales_order_entry.pending_delivery
      self.errors.add(:quantity, "Harus di antara 0 dan #{ sales_order_entry.pending_delivery}")
      return self 
    end
    
    # if there is no such item @ the given warehouse => tadaaaa.. boom boom boom no item. 
    warehouse_item = self.warehouse_item 
    return if warehouse_item.nil?
    
    if warehouse_item.ready < quantity 
      msg = "Jumlah stock ready di gudang #{warehouse_item.warehouse.name} hanya #{warehouse_item.ready}"
      self.errors.add(:quantity, msg )
      return self
    end
  end
  
  def uniq_sales_order_entry_id  
    return if not all_fields_present?
    
    begin
      
      parent = self.sales_delivery
      sales_delivery_entry_count = SalesDeliveryEntry.where(
        :sales_order_entry_id => self.sales_order_entry_id,
        :sales_delivery_id => parent.id  
      ).count 

      sales_order_entry = self.sales_order_entry 
      sales_delivery = self.sales_delivery
      sales_order = sales_order_entry.sales_order 
      msg = "Item #{sales_order_entry.item.name} dari pemesanan #{sales_order.code} sudah terdaftar di pengantaran ini"

      if not self.persisted? and sales_delivery_entry_count != 0
        errors.add(:sales_order_entry_id , msg ) 
      elsif self.persisted? and not self.sales_order_entry_id_changed? and sales_delivery_entry_count > 1 
        errors.add(:sales_order_entry_id , msg ) 
      elsif self.persisted? and  self.sales_order_entry_id_changed? and sales_delivery_entry_count  != 0 
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
    new_object.sales_delivery_id = params[:sales_delivery_id]
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
    self.sales_delivery_id = params[:sales_delivery_id]
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
      StockMutation.create_sales_delivery_entry_stock_mutations( self ) 
      sales_order_entry.update_pending_receival_and_received( self.quantity )
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
  
  # def pending_receival
  #   quantity - received
  # end
  
=begin
  effect of purchase return confirm: received add , pending_receival deduct
  effect of purchase return unconfirm: received deduct, pending_receival add 
=end
  def can_be_unconfirmed?
    reverse_adjustment_quantity = -1*quantity  
    
    # puts "initial item.pending_receival: #{item.pending_receival}"
    # puts "the reverse adjusetment: #{reverse_adjustment_quantity}"
    final_item_ready_quantity = item.ready  + reverse_adjustment_quantity
    final_warehouse_item_ready_quantity = warehouse_item.ready  + reverse_adjustment_quantity
    
    if final_item_ready_quantity < 0 or final_warehouse_item_ready_quantity < 0 
      # another condition: sales_order_entry.pending_receival > ordered_quantity
      msg = "Tidak bisa unconfirm karena akan menyebabkan jumlah #{item.name} pending receival menjadi #{final_item_ready_quantity} " + 
                " dan jumlah item gudang menjadi :#{final_warehouse_item_ready_quantity}"
      self.errors.add(:generic_errors, msg )
      return false 
    end
    
    final_sales_order_entry_received = sales_order_entry.pending_receival + reverse_adjustment_quantity 
    if final_sales_order_entry_received < 0 
      msg = "Tidak bisa unconfirm karena akan menyebabkan jumlah #{item.name} yang diterima menjadi " + 
              " lebih kecil dari 0 (#{final_sales_order_entry_pending_receival})"
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
      sales_order_entry.update_pending_receival_and_received( -1*self.quantity )
    end
  end
end
