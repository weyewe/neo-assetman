class PurchaseReturn < ActiveRecord::Base
  belongs_to :supplier 
  has_many :purchase_return_entries
  
  validates_presence_of  :supplier_id, :code, :received_at
  validates_uniqueness_of :code 
  
  validate :valid_supplier_id
  validate :valid_code
  
  def all_fields_present?
    received_at.present? and
    supplier_id.present? and 
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
  
  def valid_code 
    if code.present? and code.length == 0 
      self.errors.add(:code, "Kode pengembalian barang harus ada")
      return self 
    end
  end
  
  def self.create_object( params )
    new_object = self.new
    new_object.supplier_id = params[:supplier_id]
    new_object.received_at = params[:received_at]
    new_object.code = params[:code]
    
    new_object.save
    return new_object
  end
  
  def update_object(params)
    if self.is_confirmed?
      self.errors.add(:generic_errors, "Sudah konfirmasi")
      return self 
    end
    
    self.supplier_id = params[:supplier_id]
    self.received_at = params[:received_at]
    self.code = params[:code]

    self.save
    return self
  end
  
  def delete_object
    if self.is_confirmed?
      self.errors.add(:generic_errors, "Sudah konfirmasi")
      return self 
    end
    
    if self.purchase_return_entries.count != 0
      self.errors.add(:generic_errors, "Sudah ada purchase return entry")
      return self 
    end
    
    self.purchase_return_entries.each {|x| x.delete_object}
    self.destroy
  end
  
  def confirm
    return if self.is_confirmed? 
    if self.purchase_return_entries.count == 0 
      self.errors.add(:generic_errors, "Tidak ada yang dikembalikan. silakan tambah pengembalian.")
      return self 
    end
    
    
    self.purchase_return_entries.each {|x| x.confirm }
    
    
    self.is_confirmed = true 
    self.confirmed_at = DateTime.now
    self.save
  end
  
  def unconfirm 
    return if not self.is_confirmed?
    
    self.purchase_return_entries.each do |pre|
      if not pre.can_be_unconfirmed?
        # self.errors.add(:test_error, "Awesome")
        # puts self.errors.messages[:test_error].first
        # puts self.errors.messages[:awesome_error].first
        self.errors.add(:generic_errors, pre.errors.messages[:generic_errors].first)
        return self 
      end
    end

    
    self.is_confirmed = false 
    self.save
    self.purchase_return_entries.each {|x| x.unconfirm }
  end
end
