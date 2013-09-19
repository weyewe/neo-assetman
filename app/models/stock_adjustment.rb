class StockAdjustment < ActiveRecord::Base
  has_many :stock_adjustment_entries 
  belongs_to :supplier 
  
  
  validates_presence_of   :warehouse_id, :code , :adjusted_at 
  validates_uniqueness_of :code 
  
  validate :valid_warehouse_id 
  validate :valid_code
  
  def valid_code
    if code.present? and code.length == 0
      self.errors.add(:code, "Harus ada code PO")
      return self 
    end
  end
  
  def all_fields_present?
    warehouse_id.present? and 
    code.present?   
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
    new_object.adjusted_at = params[:adjusted_at]
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
    
    if self.stock_adjustment_entries.count != 0 and 
      warehouse_id != params[:warehouse_id]
      self.errors.add(:warehouse_id, "Tidak boleh mengganti gudang. Sudah ada adjustment")
      return self 
    end
    
    self.adjusted_at = params[:adjusted_at]
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
    
    if self.stock_adjustment_entries.count != 0
      self.errors.add(:generic_errors, "Sudah ada stock adjustment entry")
      return self 
    end
    
    self.stock_adjustment_entries.each {|x| x.delete_object}
    self.destroy 
  end
  
  def confirm
    return if self.is_confirmed? 
    if self.stock_adjustment_entries.count == 0 
      self.errors.add(:generic_errors, "Tidak ada yang dibeli. silakan tambah pembelian.")
      return self 
    end
    
    self.stock_adjustment_entries.each do |sae|
      if not sae.can_be_confirmed? 
        self.errors.add(:generic_errors, sae.errors.messages[:generic_errors].first)
        return self
      end
    end
    
    
    self.stock_adjustment_entries.each {|x| x.confirm }
    
    
    self.is_confirmed = true 
    self.confirmed_at = DateTime.now
    self.save
    
  end
  
  def unconfirm
    return if not self.is_confirmed?
    
    self.stock_adjustment_entries.each do |sae|
      if not sae.can_be_unconfirmed?
        self.errors.add(:generic_errors, sae.errors.messages[:generic_errors].first)
        return self 
      end
    end

    
    self.is_confirmed = false 
    self.save
    self.stock_adjustment_entries.each {|x| x.unconfirm }
  end
  
end
