class Item < ActiveRecord::Base
  has_many :warehouses, :through => :warehouse_item 
  has_many :warehouse_items 
  
  # stock mutation sources 
  has_many :stock_adjustments 
  
  validates_uniqueness_of :name, :code 
  
  def self.create_object(params)
    new_object = self.new 
    new_object.name = params[:name]
    new_object.code = params[:code ]
    new_object.description = params[:description ]
    
    new_object.save 
    
    return new_object
  end
  
  def update_object(params) 
    self.name = params[:name]
    self.code = params[:code ]
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
  
  def update_ready( diff ) 
    self.ready += diff
    self.save
  end
  
  def update_pending_receival( diff ) 
    self.pending_receival += diff 
    self.save 
  end
  
  def update_pending_delivery( diff ) 
    self.pending_delivery += diff 
    self.save 
  end
  
  
end
