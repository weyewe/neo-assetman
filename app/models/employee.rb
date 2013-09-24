class Employee < ActiveRecord::Base
  has_many :job_orders 
  
  validates_presence_of :name
  validates_uniqueness_of :name 
  
  
  def self.create_object( params ) 
    new_object = self.new
    new_object.name = params[:name]
    new_object.save
    return new_object
  end
  
  def update_object( params ) 
    self.name = params[:name]
    self.save
    return self 
  end
  
  def delete_object( params ) 
    if self.job_orders.count != 0 
      self.errors.add(:generic_errors, "Sudah ada job order")
      return self 
    end
    
    self.destroy 
  end
end
