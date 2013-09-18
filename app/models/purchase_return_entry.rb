class PurchaseReturnEntry < ActiveRecord::Base
  has_many :stock_mutations,  :as => :stock_mutation_source
  # 1 stock mutation to deduct pending_receival
  # 1 stock mutation to add ready 
  belongs_to :purchase_return
  belongs_to :purchase_order_entry 
  
  
  validates_presence_of :purchase_return_id , :purchase_order_entry_id, :quantity
  
  validate :valid_purchase_return_id
  validate :valid_purchase_order_entry_id 
  validate :valid_quantity
  validate :uniq_purchase_order_entry_id 
  validate :confirmed_purchase_order_entry
  
  def all_fields_present?
    purchase_return_id.present? and
    purchase_order_entry_id.present? and 
    quantity.present? 
  end
  
  def valid_purchase_return_id
    return if not self.all_fields_present? 
    
    begin
       PurchaseReturn.find purchase_return_id   
    rescue
      self.errors.add(:purchase_return_id, "Harus memilih dokumen pengembalian") 
      return self 
    end
  end
  
  def valid_purchase_order_entry_id
    return if not self.all_fields_present? 
    
    begin
       PurchaseOrderEntry.find purchase_order_entry_id   
    rescue
      self.errors.add(:purchase_order_entry_id, "Harus memilih item dari purchase order") 
      return self 
    end
  end
  
  def valid_quantity
    return if not all_fields_present?
    
    if quantity <= 0 or quantity > purchase_order_entry.received
      self.errors.add(:quantity, "Harus di antara 0 dan #{ purchase_order_entry.received}")
    end
  end
  
  def uniq_purchase_order_entry_id
    return if not all_fields_present?
    
    begin
      
      parent = self.purchase_receival
      purchase_return_entry_count = PurchaseReturnEntry.where(
        :purchase_order_entry_id => self.purchase_order_entry_id,
        :purchase_return_id => parent.id  
      ).count 

      purchase_order_entry = self.purchase_order_entry 
      purchase_return = self.purchase_return
      purchase_order = purchase_order_entry.purchase_order 
      msg = "Item #{purchase_order_entry.item.name} dari pemesanan #{purchase_order.code} sudah terdaftar di pengembalian ini"

      if not self.persisted? and purchase_return_entry_count != 0
        errors.add(:purchase_order_entry_id , msg ) 
      elsif self.persisted? and not self.purchase_order_entry_id_changed? and purchase_return_entry_count > 1 
        errors.add(:purchase_order_entry_id , msg ) 
      elsif self.persisted? and  self.purchase_order_entry_id_changed? and purchase_return_entry_count  != 0 
        errors.add(:purchase_order_entry_id , msg )
      end
    rescue
    end
  end
  
  def confirmed_purchase_order_entry
    return if not all_fields_present? 
    
    if not purchase_order_entry.is_confirmed? 
      self.errors.add(:purchase_order_entry_id, "Belum di konfirmasi")
      return self 
    end
  end
  
  
  def self.create_object( params ) 
    new_object = self.new 
    new_object.purchase_return_id = params[:purchase_return_id]
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
    self.purchase_return_id = params[:purchase_return_id]
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
      StockMutation.create_purchase_return_entry_stock_mutations( self ) 
      purchase_order_entry.update_pending_receival_and_received( -1*self.quantity )
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
      :id => self.purchase_order_entry.item_id 
    ).first 
  end
   
   
=begin
  effect of purchase return confirm: received deduct , pending_receival add
  effect of purchase return unconfirm: received add, pending_receival negative 
=end
  def can_be_unconfirmed?
    reverse_adjustment_quantity = quantity  
    
    # puts "initial item.pending_receival: #{item.pending_receival}"
    # puts "the reverse adjusetment: #{reverse_adjustment_quantity}"
    # final_item_ready_quantity = item.ready  + reverse_adjustment_quantity
    # final_warehouse_item_ready_quantity = warehouse_item.ready  + reverse_adjustment_quantity
    # 
    # # this block is irrelevant. unconfirm will always add the ready item.
    # if final_item_ready_quantity < 0 or final_warehouse_item_ready_quantity < 0 
    #   # another condition: if the pending_receival_quantity > ordered quantity
    #   msg = "Tidak bisa unconfirm karena akan menyebabkan jumlah #{item.name} pending receival menjadi #{final_item_ready_quantity} " + 
    #             " dan jumlah item gudang menjadi :#{final_warehouse_item_ready_quantity}"
    #   self.errors.add(:generic_errors, msg )
    #   return false 
    # end
    
    final_purchase_order_entry_received = purchase_order_entry.received + reverse_adjustment_quantity 
    if final_purchase_order_entry_received  >  purchase_order_entry.quantity 
      msg = "Tidak bisa unconfirm karena akan menyebabkan jumlah #{item.name}  yang diterima menjadi "  + 
            " lebih dari yang dipesan: #{purchase_order_entry.quantity }."
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
      purchase_order_entry.update_pending_receival_and_received( *self.quantity )
    end
  end
end
