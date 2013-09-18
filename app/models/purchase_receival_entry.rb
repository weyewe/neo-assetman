class PurchaseReceivalEntry < ActiveRecord::Base
  has_many :stock_mutations,  :as => :stock_mutation_source
  # 1 stock mutation to deduct pending_receival
  # 1 stock mutation to add ready 
  belongs_to :purchase_receival
  belongs_to :purchase_order_entry 
  
  
  validates_presence_of :purchase_receival_id , :purchase_order_entry_id, :quantity
  
  validate :valid_purchase_receival_id
  validate :valid_purchase_order_entry_id 
  validate :valid_quantity
  
  def all_fields_present?
    purchase_receival_id.present? and
    purchase_order_entry_id.present? and 
    quantity.present? 
  end
  
  def valid_purchase_receival_id
    return if not self.all_fields_present? 
    
    begin
       PurchaseReceival.find purchase_receival_id   
    rescue
      self.errors.add(:purchase_receival_id, "Harus memilih dokumen penerimaan") 
      return self 
    end
  end
  
  def valid_purchase_order_entry_id
    return if not self.all_fields_present? 
    
    begin
       Supplier.find supplier_id   
    rescue
      self.errors.add(:supplier_id, "Harus memilih supplier") 
      return self 
    end
  end
  
  def valid_quantity
    return if not all_fields_present?
    
    if quantity < 0 or quantity > purchase_order_entry.pending_receival
      self.errors.add(:quantity, "Harus di antara 0 dan #{ purchase_order_entry.pending_receival}")
    end
  end
  
  def self.create_object( params ) 
    new_object = self.new 
    new_object.purchase_receival_id = params[:purchase_receival_id]
    new_object.purchase_order_entry_id = params[:purchase_order_entry_id]
    new_object.quantity  = params[:quantity]
    
    new_object.save 
    return new_object
    
  end
  
  def update_object( params )
    if self.is_confirmed?
      self.errors.add(:generic_errors, "Sudah dikonfirmasi")
      return self 
    end
    self.purchase_receival_id = params[:purchase_receival_id]
    self.purchase_order_entry_id = params[:purchase_order_entry_id]
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
  
  def confirm
    return if self.is_confirmed? 
    
    self.is_confirmed = true 
    self.confirmed_at = DateTime.now 
    if self.save 
      StockMutation.create_purchase_receival_entry_stock_mutations( self ) 
      purchase_order_entry.update_pending_receival( self.quantity )
    end
  end
  
  
  def warehouse_item
    WarehouseItem.find_or_create_object( 
      :warehouse_id => self.purchase_order_entry.purchase_order.warehouse_id , 
      :item_id => self.purchase_order_entry.item_id 
    )
  end
  
  def item
    Item.where(
      :item_id => self.purchase_order_entry.item_id 
    ).first 
  end
  
  # def pending_receival
  #   quantity - received
  # end
  
  def can_be_unconfirmed?
    reverse_adjustment_quantity = -1*quantity  
    
    # puts "initial item.pending_receival: #{item.pending_receival}"
    # puts "the reverse adjusetment: #{reverse_adjustment_quantity}"
    final_item_ready_quantity = item.ready  + reverse_adjustment_quantity
    final_warehouse_item_ready_quantity = warehouse_item.ready  + reverse_adjustment_quantity
    
    if final_item_ready_quantity < 0 or final_warehouse_item_ready_quantity < 0 
      msg = "Tidak bisa unconfirm karena akan menyebabkan jumlah #{item.name} pending receival menjadi #{final_item_ready_quantity} " + 
                " dan jumlah item gudang menjadi :#{final_warehouse_item_ready_quantity}"
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
      purchase_order_entry.update_pending_receival( -1*self.quantity )
    end
  end
end
