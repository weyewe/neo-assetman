class SalesDelivery < ActiveRecord::Base
  belongs_to :customer 
  has_many :sales_delivery_entries
  belongs_to :warehouse 
  
  validates_presence_of  :customer_id, :code, :delivered_at, :warehouse_id 
  validates_uniqueness_of :code 
  
  validate :valid_customer_id
  validate :valid_code
  validate :valid_warehouse_id 
  
  def all_fields_present?
    delivered_at.present? and
    customer_id.present? and 
    code.present?
  end
  
   
  def valid_customer_id
    return if not self.all_fields_present? 
    
    begin
       Customer.find customer_id   
    rescue
      self.errors.add(:customer_id, "Harus memilih customer") 
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
  
  def valid_code 
    if code.present? and code.length == 0 
      self.errors.add(:code, "Kode penerimaan barang harus ada")
      return self 
    end
  end
  
  def valid_sales_delivery_id
    return if not self.all_fields_present? 
    
    begin
       Warehouse.find warehouse_id   
    rescue
      self.errors.add(:warehouse_id, "Harus memilih gudang keluar barang") 
      return self 
    end
  end
  
  def self.create_object( params )
    new_object = self.new
    new_object.customer_id = params[:customer_id]
    new_object.delivered_at = params[:delivered_at]
    new_object.warehouse_id = params[:warehouse_id]
    new_object.code = params[:code]
    
    new_object.save
    return new_object
  end
  
  def update_object(params)
    if self.is_confirmed?
      self.errors.add(:generic_errors, "Sudah konfirmasi")
      return self 
    end
    
    self.customer_id = params[:customer_id]
    self.delivered_at = params[:delivered_at]
    self.warehouse_id = params[:warehouse_id]
    self.code = params[:code]

    self.save
    return self
  end
  
  def delete_object
    if self.is_confirmed?
      self.errors.add(:generic_errors, "Sudah konfirmasi")
      return self 
    end
    
    if self.sales_delivery_entries.count != 0
      self.errors.add(:generic_errors, "Sudah ada sales delivery entry")
      return self 
    end
    
    self.sales_delivery_entries.each {|x| x.delete_object}
    self.destroy
  end
  
  def confirm
    return if self.is_confirmed? 
    if self.sales_delivery_entries.count == 0 
      self.errors.add(:generic_errors, "Tidak ada yang diterima. silakan tambah penerimaan.")
      return self 
    end
    
    
    self.sales_delivery_entries.each do |pre|
      if not pre.can_be_confirmed? 
        self.errors.add(:generic_errors, pre.errors.messages[:generic_errors].first)
        return self
      end
    end
    
    self.sales_delivery_entries.each {|x| x.confirm }
    
    
    self.is_confirmed = true 
    self.confirmed_at = DateTime.now
    self.save
  end
  
  def unconfirm 
    return if not self.is_confirmed?
    
    self.sales_delivery_entries.each do |sde|
      if not sde.can_be_unconfirmed?
        self.errors.add(:generic_errors, sde.errors.messages[:generic_errors].first)
        return self 
      end
    end

    
    self.is_confirmed = false 
    self.save
    self.sales_delivery_entries.each {|x| x.unconfirm }
  end
end
