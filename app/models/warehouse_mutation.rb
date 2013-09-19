class WarehouseMutation < ActiveRecord::Base
  validates_presence_of  :source_warehouse_id, 
                        :target_warehouse_id,
                        :code, 
                        :mutated_at 
                        
  validates_uniqueness_of :code 
  
  validate :valid_source_and_target_warehouse_id
  
  has_many :warehouse_mutation_entries 
  
  
  def all_fields_present? 
    source_warehouse_id.present?  and 
    target_warehouse_id.present? and 
    code.present?  and code.length != 0 
  end
  
  
  def valid_source_and_target_warehouse_id 
    return if not all_fields_present? 
    
    begin
       source = Warehouse.find source_warehouse_id   
       target = Warehouse.find target_warehouse_id 
    rescue
      msg = "Harus memilih gudang"
      self.errors.add(:source_warehouse_id, msg ) 
      self.errors.add(:target_warehouse_id, msg ) 
      return self 
    end
    
    if source.id == target.id 
      msg = "Source Warehouse tidak boleh sama dengan Target Warehouse"
      self.errors.add(:source_warehouse_id, msg) 
      self.errors.add(:target_warehouse_id, msg)
      return self 
    end
  end
  
  def self.create_object( params ) 
    new_object = self.new
    new_object.mutated_at = params[:mutated_at]
    new_object.source_warehouse_id = params[:source_warehouse_id ] 
    new_object.target_warehouse_id = params[:target_warehouse_id ] 
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
    
    if self.warehouse_mutation_entries.count != 0 and 
        (
          source_warehouse_id != params[:source_warehouse_id] or 
          target_warehouse_id != params[:target_warehouse_id]
        )
      
      self.errors.add(:source_warehouse_id, "Tidak boleh mengganti gudang. Sudah ada adjustment")
      self.errors.add(:target_warehouse_id, "Tidak boleh mengganti gudang. Sudah ada adjustment")
      return self 
    end
    
    self.mutated_at = params[:mutated_at]
    self.source_warehouse_id = params[:source_warehouse_id ] 
    self.target_warehouse_id = params[:target_warehouse_id ] 
    self.description = params[:description]
    self.code  = params[:code]
    
    self.save 
    return self 
  end

  def delete_object
    if self.is_confirmed?
      self.errors.add(:generic_errors, "Sudah dikonfirmasi")
      return self
    end
    
    if self.warehouse_mutation_entries.count != 0
      self.errors.add(:generic_errors, "Sudah ada warehouse mutation entry")
      return self 
    end
    
    self.warehouse_mutation_entries.each {|x| x.delete_object}
    self.destroy
  end
  
  def confirm
    return if self.is_confirmed? 
    if self.warehouse_mutation_entries.count == 0 
      self.errors.add(:generic_errors, "Tidak ada yang dimutasi. silakan tambah mutasi.")
      return self 
    end
    
    self.warehouse_mutation_entries.each do |wme|
      if not wme.can_be_confirmed? 
        self.errors.add(:generic_errors, wme.errors.messages[:generic_errors].first)
        return self
      end
    end
    
    
    self.warehouse_mutation_entries.each {|x| x.confirm }
    
    self.is_confirmed = true 
    self.confirmed_at = DateTime.now
    self.save
  end
  
  def unconfirm
    return if not self.is_confirmed?
    
    self.warehouse_mutation_entries.each do |wme|
      if not wme.can_be_unconfirmed?
        self.errors.add(:generic_errors, wme.errors.messages[:generic_errors].first)
        return self 
      end
    end

    
    self.is_confirmed = false 
    self.save
    self.warehouse_mutation_entries.each {|x| x.unconfirm }
  end
  
end
