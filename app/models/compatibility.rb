class Compatibility < ActiveRecord::Base
  belongs_to :component
  belongs_to :item 
  
  validates_presence_of :component_id, :item_id 
  
  validate :uniqueness_of_component_item_pair
  validate :valid_component_id
  validate :valid_item_id 
  
  def all_fields_present?
    component_id.present? and
    item_id.present? 
  end
  
  def valid_component_id
    return if not self.all_fields_present? 
    
    begin
       Component.find component_id   
    rescue
      self.errors.add(:component_id, "Harus memilih komponen") 
      return self 
    end
  end
  
  def valid_item_id
    return if not self.all_fields_present? 
    
    begin
       Item.find item_id   
    rescue
      self.errors.add(:item_id, "Harus memilih item") 
      return self 
    end
  end
  
  
  
  def uniqueness_of_component_item_pair
    return if not all_fields_present?
    
    begin
      
      parent = self.component
      compatibility_count = Compatibility.where(
        :item_id => self.item_id,
        :component_id => parent.id  
      ).count 
  
      msg = "Item #{item.name} sudah terdaftar di component : #{component.name}"

      if not self.persisted? and compatibility_count != 0
        errors.add(:item_id , msg ) 
      elsif self.persisted? and not self.item_id_changed? and compatibility_count > 1 
        errors.add(:item_id , msg ) 
      elsif self.persisted? and  self.item_id_changed? and compatibility_count  != 0 
        errors.add(:item_id , msg )
      end
    rescue
    end
  end
  
  def self.create_object( params )
    new_object = self.new
    new_object.component_id = params[:component_id]
    new_object.item_id = params[:item_id]
    new_object.save 
    
    return new_object
  end
  
  def update_object( params ) 
    self.component_id = params[:component_id]
    self.item_id = params[:item_id]
    self.save 
    
    return self
  end
  
  def delete_object
    if ComponentHistory.where(
        :item_id => self.item_id , 
        :component_id => self.component_id
      ).count != 0 
      self.errors.add(:generic_errors, "Sudah ada perbaikan dengan item ini")
      return self 
    end
    
    if JobOrderEntry.where(
      :is_confirmed => true, 
      :component_id => self.component_id, 
      :item_id => self.item_id,
      :result_case =>   JOB_ORDER_ENTRY_RESULT_CASE[:broken]  ,
      :is_replaced => true 
    ).count != 0 
      self.errors.add(:generic_errors, "Sudah ada penggantian dengan item ini")
      return self 
    end
    
    self.destroy 
  end
  
end


