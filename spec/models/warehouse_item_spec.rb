require 'spec_helper'

describe WarehouseItem do
  before(:each) do
    @wh_1 = Warehouse.create_object(
      :name => "Warehouse 1",
      :description => "Our main warehouse"
    )
    
    @item_1 = Item.create_object(
      :name => "Hose 5m",
      :code => "HS34"
    )
  end
  
  it 'should create item' do
    @wh_1.should be_valid 
    @item_1.should be_valid 
  end
   
  it 'should have 0 warehouse-item' do
    WarehouseItem.count.should == 0 
  end
   
  it 'should create warehouse item using WarehouseItem.find_or_create_object' do
    
    WarehouseItem.where(
      :warehouse_id => @wh_1.id , 
      :item_id => @item_1.id 
    ).count.should == 0 
    
    puts "THE FIRST CALL"
    object1 = WarehouseItem.find_or_create_object(
      :warehouse_id => @wh_1.id , 
      :item_id => @item_1.id 
    )
    
    
    object1.should be_valid 
    
    puts "THE second CALL"
    object2 = WarehouseItem.find_or_create_object(
      :warehouse_id => @wh_1.id , 
      :item_id => @item_1.id 
    ) 
    
    object2.should be_valid 
    
    object1.id.should == object2.id 
  end
end
