class Asset < ActiveRecord::Base
  has_many :component_histories
  belongs_to :machine 
  belongs_to :customer 
  has_many :job_orders 
  
  validates_uniqueness_of :code 
  validates_presence_of :customer_id, :code, :machine_id 
  
  validate :valid_customer_id
  validate :valid_machine_id 
  
  
  def all_fields_present?
    customer_id.present? and machine_id.present? 
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
  
  def valid_machine_id
    return if not self.all_fields_present? 
    
    begin
       Machine.find machine_id   
    rescue
      self.errors.add(:machine_id, "Harus memilih mesin") 
      return self 
    end
  end
  
  def setup_component_histories
    # refresh data
    self.component_histories.each {|x| x.delete_object}
    
    self.machine.components.each do |component|
      ComponentHistory.create_setup_object( self, component ) 
    end
  end
  
  def self.create_object( params ) 
    new_object = self.new 
    new_object.customer_id = params[:customer_id]
    new_object.machine_id = params[:machine_id]
    new_object.code = params[:code]
    
    if new_object.save
      new_object.setup_component_histories 
    end
    
    return new_object
  end
  
  
  
  def update_object( params  )
    if self.has_maintenance?
      self.errors.add(:generic_errors, "Sudah ada perbaikan")
      return self
    end
    
   
    
    is_machine_id_changed = false 
    if self.machine_id != params[:machine_id].to_i
      is_machine_id_changed = true 
    end
    
    self.customer_id = params[:customer_id]
    self.machine_id = params[:machine_id]
    self.code = params[:code]
    
    
    if is_machine_id_changed and self.job_orders.count != 0
      self.errors.add(:machine_id, "Tidak bisa merubah mesin karena sudah ada pengerjaan")
      return self 
    end

    self.save 
    
    return self 
  end
  
  def has_maintenance?
    self.component_histories.where(:case => COMPONENT_HISTORY_CASE[:maintenance]).count != 0 
  end
  
  def delete_object
    if self.has_maintenance?
      self.errors.add(:generic_errors, "Sudah ada perbaikan")
      return self 
    end
    
    
    # must be the initial setup component history 
    self.component_histories.each {|x| x.delete_object }
    self.destroy 
  end
  
  
end
