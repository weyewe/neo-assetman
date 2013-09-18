class StockMutation < ActiveRecord::Base
  belongs_to :stock_mutation_source, :polymorphic => true 
  
  # has_many :transaction_activities, :as => :transaction_source
  belongs_to :item
  belongs_to :warehouse_item 
  belongs_to :warehouse 
  
  
  
  # def self.create_object( params ) 
  #   # if there is no warehouse_item 
  #   # create the target warehouse item. 
  # end
  # 
  # def update_object( params ) 
  #   # if the new target doesn't have warehouse_item
  #   # create the target warehouse_item 
  # end
  
  def delete_object  
    diff = -1*self.quantity 
    
    self.update_quantity( diff  )
    self.destroy 
  end
  
  
  def update_quantity( diff )  
    stock_mutation_case = self.case 
    
    if stock_mutation_case == STOCK_MUTATION_CASE[:ready]
      warehouse_item.update_ready( diff  )
      item.update_ready( diff  )
    elsif stock_mutation_case == STOCK_MUTATION_CASE[:pending_receival]
      warehouse_item.update_pending_receival( diff  )
      item.update_pending_receival( diff  )
    elsif stock_mutation_case == STOCK_MUTATION_CASE[:pending_delivery]
      warehouse_item.update_pending_delivery( diff  )
      item.update_pending_delivery( diff  )
    end
  end
  
  
  def self.create_stock_adjustment_mutation(sms)
    new_object = self.new 
    new_object.stock_mutation_source_type = sms.class.to_s
    new_object.stock_mutation_source_id = sms.id 
    new_object.warehouse_id = sms.warehouse_id
    new_object.warehouse_item_id = sms.warehouse_item_id 
    new_object.item_id = sms.item_id 
    
    new_object.quantity = sms.diff 
    new_object.mutated_at = sms.confirmed_at 
    new_object.case = STOCK_MUTATION_CASE[:ready]
    
    if new_object.save 
      new_object.update_quantity( new_object.quantity )
    end
  end
  
=begin
  Warehouse Stock Mutation
=end

  def self.create_deduction_from_source_warehouse( sms ) 
    warehouse_item = WarehouseItem.find_or_create_object(
      :warehouse_id => sms.source_warehouse_id , 
      :item_id => sms.item_id 
    ) 
    
    new_object = self.new 
    new_object.stock_mutation_source_type = sms.class.to_s
    new_object.stock_mutation_source_id = sms.id 
    new_object.warehouse_id = sms.source_warehouse_id 
    new_object.warehouse_item_id = warehouse_item.id 
    new_object.item_id = sms.item_id 
    
    new_object.quantity = -1*sms.quantity 
    new_object.mutated_at = sms.confirmed_at 
    new_object.case = STOCK_MUTATION_CASE[:ready]
    
    if new_object.save 
      new_object.update_quantity( new_object.quantity )
    end
  end
  
  def self.create_addition_to_target_warehouse( sms )
    warehouse_item = WarehouseItem.find_or_create_object(
      :warehouse_id => sms.target_warehouse_id , 
      :item_id => sms.item_id 
    ) 
    
    new_object = self.new 
    new_object.stock_mutation_source_type = sms.class.to_s
    new_object.stock_mutation_source_id = sms.id 
    new_object.warehouse_id = sms.target_warehouse_id 
    new_object.warehouse_item_id = warehouse_item.id 
    new_object.item_id = sms.item_id 
    
    new_object.quantity = sms.quantity 
    new_object.mutated_at = sms.confirmed_at 
    new_object.case = STOCK_MUTATION_CASE[:ready]
    
    if new_object.save 
      new_object.update_quantity( new_object.quantity )
    end
  end
  
  
  def self.create_warehouse_item_mutation_stock_mutation( sms ) 
    self.create_deduction_from_source_warehouse(sms)
    self.create_addition_to_target_warehouse( sms ) 
  end
  
=begin
  Purchase Order Entry
=end
  def self.create_purchase_order_entry_stock_mutation( poe)
    warehouse_item = WarehouseItem.find_or_create_object(
      :warehouse_id => poe.purchase_order.warehouse_id , 
      :item_id => poe.item_id 
    ) 
    
    new_object = self.new 
    new_object.stock_mutation_source_type = poe.class.to_s
    new_object.stock_mutation_source_id = poe.id 
    new_object.warehouse_id = poe.purchase_order.warehouse_id 
    new_object.warehouse_item_id = warehouse_item.id 
    new_object.item_id = poe.item_id 
    
    new_object.quantity = poe.quantity 
    new_object.mutated_at = poe.confirmed_at 
    new_object.case = STOCK_MUTATION_CASE[:pending_receival]
    
    if new_object.save 
      new_object.update_quantity( new_object.quantity )
    end
  end
  
=begin
  Purchase Receival entry
=end
  def self.create_purchase_receival_entry_deduct_pending_receival(sms)
    warehouse_item = WarehouseItem.find_or_create_object(
      :warehouse_id => sms.purchase_order_entry.purchase_order.warehouse_id , 
      :item_id => sms.purchase_order_entry.item_id 
    )
    new_object = self.new 
    new_object.stock_mutation_source_type = sms.class.to_s
    new_object.stock_mutation_source_id = sms.id 
    new_object.warehouse_id = sms.purchase_order_entry.purchase_order.warehouse_id 
    new_object.warehouse_item_id = warehouse_item.id 
    new_object.item_id =  sms.purchase_order_entry.item_id 
    
    new_object.quantity = -1*sms.quantity 
    new_object.mutated_at = sms.confirmed_at 
    new_object.case = STOCK_MUTATION_CASE[:pending_receival]
    
    if new_object.save 
      new_object.update_quantity( new_object.quantity )
    end
  end
  
  def self.create_purchase_receival_entry_add_ready(sms)
    warehouse_item = WarehouseItem.find_or_create_object(
      :warehouse_id => sms.purchase_order_entry.purchase_order.warehouse_id , 
      :item_id => sms.purchase_order_entry.item_id 
    )
    new_object = self.new 
    new_object.stock_mutation_source_type = sms.class.to_s
    new_object.stock_mutation_source_id = sms.id 
    new_object.warehouse_id = sms.purchase_order_entry.purchase_order.warehouse_id 
    new_object.warehouse_item_id = warehouse_item.id 
    new_object.item_id =  sms.purchase_order_entry.item_id 
    
    new_object.quantity = sms.quantity 
    new_object.mutated_at = sms.confirmed_at 
    new_object.case = STOCK_MUTATION_CASE[:ready]
    
    if new_object.save 
      new_object.update_quantity( new_object.quantity )
    end
  end

  def self.create_purchase_receival_entry_stock_mutations( sms )
    self.create_purchase_receival_entry_deduct_pending_receival(sms)
    self.create_purchase_receival_entry_add_ready( sms ) 
  end
  
=begin
  Purchase Return
=end

  def self.create_purchase_receival_entry_add_pending_receival(sms)
    warehouse_item = WarehouseItem.find_or_create_object(
      :warehouse_id => sms.purchase_order_entry.purchase_order.warehouse_id , 
      :item_id => sms.purchase_order_entry.item_id 
    )
    new_object = self.new 
    new_object.stock_mutation_source_type = sms.class.to_s
    new_object.stock_mutation_source_id = sms.id 
    new_object.warehouse_id = sms.purchase_order_entry.purchase_order.warehouse_id 
    new_object.warehouse_item_id = warehouse_item.id 
    new_object.item_id =  sms.purchase_order_entry.item_id 
    
    new_object.quantity = sms.quantity 
    new_object.mutated_at = sms.confirmed_at 
    new_object.case = STOCK_MUTATION_CASE[:pending_receival]
    
    if new_object.save 
      new_object.update_quantity( new_object.quantity )
    end
  end
  
  def self.create_purchase_receival_entry_deduct_ready(sms)
    warehouse_item = WarehouseItem.find_or_create_object(
      :warehouse_id => sms.purchase_order_entry.purchase_order.warehouse_id , 
      :item_id => sms.purchase_order_entry.item_id 
    )
    new_object = self.new 
    new_object.stock_mutation_source_type = sms.class.to_s
    new_object.stock_mutation_source_id = sms.id 
    new_object.warehouse_id = sms.purchase_order_entry.purchase_order.warehouse_id 
    new_object.warehouse_item_id = warehouse_item.id 
    new_object.item_id =  sms.purchase_order_entry.item_id 
    
    new_object.quantity = -1*sms.quantity 
    new_object.mutated_at = sms.confirmed_at 
    new_object.case = STOCK_MUTATION_CASE[:ready]
    
    if new_object.save 
      new_object.update_quantity( new_object.quantity )
    end
  end

  def self.create_purchase_return_entry_stock_mutations(sms)
    self.create_purchase_receival_entry_add_pending_receival(sms)
    self.create_purchase_receival_entry_deduct_ready( sms )
  end
end
