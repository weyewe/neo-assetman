class Component < ActiveRecord::Base
  belongs_to :machine 
  has_many :items, :through => :compatibilities
  has_many :compatibilities 
  has_many :component_histories 
  
  validates_presence_of :machine_id, :name 
  
  
  def all_fields_present?
    machine_id.present? 
  end
  
  def valid_machine_id
    return if not self.all_fields_present? 
    
    begin
       Machine.find valid_machine_id   
    rescue
      self.errors.add(:valid_machine_id, "Harus memilih customer") 
      return self 
    end
  end
  
  def update_component_history_and_job_entry
    machine.assets.each do |asset|
      
      ComponentHistory.create_setup_object( asset, new_object )
      JobOrder.where(:asset_id => asset.id, :is_confirmed => false).each do |jo|
        JobOrderEntry.create_object(
          :job_order_id => jo.id, 
          :component_id => new_object.id 
        )
      end
    end
  end
  
  def self.create_object( params ) 
    new_object = self.new 
    new_object.machine_id = params[:machine_id]
    new_object.name = params[:name]
    
    new_object.update_component_history_and_job_entry if new_object.save
    return new_object 
  end
  
  def update_object( params ) 
    is_machine_id_changed = false 
    if self.machine_id != params[:machine_id].to_i 
      is_machine_id_changed = true 
    end
    
    if is_machine_id_changed and ComponentHistory.has_component_maintenance?(  self )
      self.errors.add(:generic_errors, "Sudah ada maintenance untuk komponen ini")
      return self
    else
      # delete the shite related to machine id: component history 
      # and the job order entries
      self.component_histories.each {|x| x.destroy }
      self.job_order_entries.each {|x| x.destroy }
    end
    
    
    
    
    self.machine_id  = params[:machine_id]
    self.name = params[:name]
    if self.save 
      if is_machine_id_changed
        self.update_component_history_and_job_entry
      end
    end
    
    return self 
  end
  
  def delete_object
    if ComponentHistory.has_component_maintenance?(  self )
      self.errors.add(:generic_errors, "Sudah ada sejarah perbaikan")
      return self 
    else
      self.component_histories.each {|x| x.delete_object }
    end
    
    if JobOrderEntry.has_confirmed_replacement_component_entry?(self)
      self.errors.add(:generic_errors, "Sudah ada job order entry yang dikonfirmasi")
      return self 
    else
      self.job_order_entries.each {|x| x.destroy } # not using delete_object because it will delete the confirmed
    end
    
    
    self.compatibilities.each {|x| x.delete_object }
    self.destroy 
    self.save 
  end
  
  
end
