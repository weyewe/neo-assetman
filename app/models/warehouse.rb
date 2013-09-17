class Warehouse < ActiveRecord::Base
  has_many :items, :through => :warehouse_items 
  has_many :warehouse_items 
  
  has_many :stock_mutations 
  has_many :stock_adjustments
  
  def self.create_object(params)
    new_object = self.new 
    new_object.name = params[:name]
    new_object.description = params[:description ]
    
    new_object.save 
      
    
    return new_object
  end
  
  def update_object(params) 
    self.name = params[:name]
    self.description = params[:description]
    
    self.save 
    
    return self 
  end
  
  def delete_object
    if self.stock_mutations.count != 0
      self.errors.add(:generic_errors, "Sudah ada mutasi barang")
      return self 
    end
    
    self.destroy 
  end
end
