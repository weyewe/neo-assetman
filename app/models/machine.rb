class Machine < ActiveRecord::Base
  has_many :assets 
  has_many :components 
  
  validates_presence_of :name 
  validates_uniqueness_of :name 
  
  def self.create_object( params ) 
    new_object =self.new 
    new_object.name = params[:name]
    new_object.save
    
    return new_object
  end
  
  def update_object( params ) 
    self.name = params[:name]
    self.save 
    
    return self 
  end
  
  def delete_object
    if self.assets.count != 0 
      self.errors.add(:generic_errors, "Sudah ada asset dari mesin ini")
      return self 
    end
    
    
    self.destroy 
  end
end
