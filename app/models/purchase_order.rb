class PurchaseOrder < ActiveRecord::Base
  has_many :purchase_order_entries 
  belongs_to :supplier 
  
  
  validates_presence_of :supplier_id , :warehouse_id, :code 
  validates_uniqueness_of :code 
  
  validate :valid_supplier_id 
  validate :valid_warehouse_id 
  validate :valid_code
  
  def valid_code
    if code.present? and code.length == 0
      self.errors.add(:code, "Harus ada code PO")
      return self 
    end
  end
  
  def all_fields_present?
    supplier_id.present? and 
    warehouse_id.present?  and 
    code.present? 
  end
  
  def valid_supplier_id
    return if not self.all_fields_present? 
    
    begin
       Supplier.find supplier_id   
    rescue
      self.errors.add(:supplier_id, "Harus memilih supplier") 
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
  
  
  def self.create_object(params)
    new_object = self.new
    new_object.supplier_id = params[:supplier_id]
    new_object.purchased_at = params[:purchased_at]
    new_object.warehouse_id = params[:warehouse_id ] 
    new_object.description = params[:description]
    new_object.code  = params[:code]
    
    new_object.save
    return new_object
  end
  
  def update_object(params)
    if self.is_confirmed?
      self.errors.add(:generic_errors, "Sudah konfirmasi, tidak bisa update")
      return self 
    end
    self.supplier_id = params[:supplier_id]
    self.purchased_at = params[:purchased_at]
    self.warehouse_id = params[:warehouse_id ] 
    self.description = params[:description]
    self.code = params[:code]
    self.save
    return self
  end
  
  def delete_object
    if self.is_confirmed?
      self.errors.add(:generic_errors, "Sudah dikonfirmasi")
      return self
    end
    
    if self.purchase_order_entries.count != 0
      self.errors.add(:generic_errors, "Sudah ada purchase order entry")
      return self 
    end
    
    self.purchase_order_entries.each {|x| x.delete_object}
    self.destroy 
  end
  
  def confirm
    return if self.is_confirmed? 
    if self.purchase_order_entries.count == 0 
      self.errors.add(:generic_errors, "Tidak ada yang dibeli. silakan tambah pembelian.")
      return self 
    end
    
    
    self.purchase_order_entries.each {|x| x.confirm }
    
    
    self.is_confirmed = true 
    self.confirmed_at = DateTime.now
    self.save
    
  end
  
  def unconfirm
    return if not self.is_confirmed?
    
    self.purchase_order_entries.each do |poe|
      if not poe.can_be_unconfirmed?
        self.errors.add(:generic_errors, poe.errors[:generic_errors])
        return self 
      end
    end

    
    self.is_confirmed = false 
    self.save
    self.purchase_order_entries.each {|x| x.unconfirm }
  end
  
end
