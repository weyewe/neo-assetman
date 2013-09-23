class JobOrderEntry < ActiveRecord::Base
  
  def self.has_confirmed_replacement_component_entry?(component)
    self.where(
      :component_id => component.id,
      :result_case => JOB_ORDER_ENTRY_RESULT_CASE[:broken],
      :is_replaced => true ,
      :is_confirmed => true 
    ).count != 0 
  end
end
