class Customer < ActiveRecord::Base
  validates_presence_of :name
  validates_uniqueness_of :name 
  
  def self.create_object( params ) 
    new_object = self.new
    new_object.name = params[:name]
    new_object.save 
    return new_object 
  end
end
