class SalesReturn < ActiveRecord::Base
  belongs_to :customer 
  has_many :sales_return_entries
  
  validates_presence_of  :customer_id, :code, :received_at, :warehouse_id 
  validates_uniqueness_of :code 
  
  validate :valid_customer_id
  validate :valid_code
  validate :valid_warehouse_id 
  
  def all_fields_present?
    received_at.present? and
    customer_id.present? and
    warehouse_id.present? and  
    code.present?
  end
  
   

  def valid_warehouse_id
    return if not self.all_fields_present? 

    begin
      Warehouse.find warehouse_id   
    rescue
      self.errors.add(:warehouse_id, "Harus memilih gudang penerimaan") 
      return self 
    end
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
  
  def valid_code 
    if code.present? and code.length == 0 
      self.errors.add(:code, "Kode pengembalian barang harus ada")
      return self 
    end
  end
  
  # 582 0495 
  def self.create_object( params )
    new_object = self.new
    new_object.customer_id = params[:customer_id]
    new_object.received_at = params[:received_at]
    new_object.code = params[:code]
    new_object.warehouse_id  = params[:warehouse_id]
    
    new_object.save
    return new_object
  end
  
  def update_object(params)
    if self.is_confirmed?
      self.errors.add(:generic_errors, "Sudah konfirmasi")
      return self 
    end
    
    if self.sales_return_entries.count != 0 and 
      customer_id != params[:customer_id]
      self.errors.add(:customer_id, "Tidak boleh mengganti customer. Sudah mengembalikan item")
      return self 
    end
    
    self.customer_id = params[:customer_id]
    self.received_at = params[:received_at]
    self.code = params[:code]
    self.warehouse_id  = params[:warehouse_id]

    self.save
    return self
  end
  
  def delete_object
    if self.is_confirmed?
      self.errors.add(:generic_errors, "Sudah konfirmasi")
      return self 
    end
    
    if self.sales_return_entries.count != 0
      self.errors.add(:generic_errors, "Sudah ada sales return entry")
      return self 
    end
    
    self.sales_return_entries.each {|x| x.delete_object}
    self.destroy
  end
  
  def confirm
    return if self.is_confirmed? 
    
    
    if self.sales_return_entries.count == 0 
      self.errors.add(:generic_errors, "Tidak ada yang dikembalikan. silakan tambah pengembalian.")
      return self 
    end
    
    self.sales_return_entries.each do |sre|
      if not sre.can_be_confirmed? 
        self.errors.add(:generic_errors, sre.errors.messages[:generic_errors].first)
        return self
      end
    end
    
    
    self.sales_return_entries.each {|x| x.confirm }
    
    
    self.is_confirmed = true 
    self.confirmed_at = DateTime.now
    self.save
  end
  
  def unconfirm 
    return if not self.is_confirmed?
    
    self.sales_return_entries.each do |pre|
      if not pre.can_be_unconfirmed? 
        self.errors.add(:generic_errors, pre.errors.messages[:generic_errors].first)
        return self 
      end
    end

    
    self.is_confirmed = false 
    self.save
    self.sales_return_entries.each {|x| x.unconfirm }
  end
end
