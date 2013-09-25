class ComponentHistory < ActiveRecord::Base
  belongs_to :asset 
  belongs_to :component
  belongs_to :item 
  belongs_to :job_order_entry
  
  
  def self.create_setup_object( asset, component ) 
    new_object = self.new 
    new_object.asset_id = asset.id 
    new_object.component_id = component.id 
    new_object.case = COMPONENT_HISTORY_CASE[:default]
    
    new_object.save 
  end
  
  def ComponentHistory.has_component_maintenance?(  component )
    self.where(:case => COMPONENT_HISTORY_CASE[:maintenance], 
              :component_id => component.id).count != 0 
  end
  
  def delete_object
    self.destroy 
  end
end
