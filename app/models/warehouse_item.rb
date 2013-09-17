class WarehouseItem < ActiveRecord::Base
  belongs_to :item
  belongs_to :warehouse
  
  validates_presence_of :item_id, :warehouse_id
  has_many :stock_mutations 
  
  has_many :stock_adjustments 
  
  def self.find_or_create_object(params)
    object = self.where(
      :item_id => params[:item_id],
      :warehouse_id => params[:warehouse_id]
    ).first 
    
    if object.nil?
      object = self.new
      object.item_id = params[:item_id]
      object.warehouse_id = params[:warehouse_id]
      object.save 
      
    end
    
    return object
    
     
  end
  
  def update_ready( diff)  
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
