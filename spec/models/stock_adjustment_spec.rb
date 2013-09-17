require 'spec_helper'

describe StockAdjustment do
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
  
  it 'should create stock adjustment' do
    @adj_quantity = 5 
    @stock_adjustment = StockAdjustment.create_object(
      :item_id => @item_1.id,
      :warehouse_id => @wh_1.id ,
      :actual_quantity => @adj_quantity
    )
    
    @stock_adjustment.should be_valid 
  end
  
  it 'should not create stock adjustment with negative actual quantity' do
    @adj_quantity = -5 
    @stock_adjustment = StockAdjustment.create_object(
      :item_id => @item_1.id,
      :warehouse_id => @wh_1.id ,
      :actual_quantity => @adj_quantity
    )
    
    @stock_adjustment.should_not be_valid
  end
  
  context "create the stock_adjustment: produces warehouse_item if it is not available" do
    before(:each) do
      @adj_quantity = 5 
      @stock_adjustment = StockAdjustment.create_object(
        :item_id => @item_1.id,
        :warehouse_id => @wh_1.id ,
        :actual_quantity => @adj_quantity
      )
      
      @stock_adjustment.reload
    end
    
    it 'should assign warehouse_item' do
      @stock_adjustment.warehouse_item_id.should_not be_nil 
      WarehouseItem.count.should == 1 
    end
    
    
    it 'should produce warehouse item' do
      # WarehouseItem.where(:warehouse_id => @wh_1.id , :item_id => @item_1.id ).count.should == 1 
      
      WarehouseItem.find_or_create_object(:warehouse_id => @wh_1.id, :item_id => @item_1.id)
      
      WarehouseItem.count.should == 1 
    end
     
    
    
  end
end
