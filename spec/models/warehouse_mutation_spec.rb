require 'spec_helper'

describe WarehouseMutation do
  before(:each) do
    @wh_1 = Warehouse.create_object(
      :name => "Warehouse 1",
      :description => "Our main warehouse"
    )
    
    @wh_2 = Warehouse.create_object(
      :name => "Warehouse 2",
      :description => "Mobile Warehouse #1"
    )
    
    @item_1 = Item.create_object(
      :name => "Hose 5m",
      :code => "HS34"
    )
    
    @item_2 = Item.create_object(
      :name => "haha Hose 5m",
      :code => "@33HS34"
    )
    
    @supplier = Supplier.create_object(
      :name => "Supplier 1 "
    )
    
    @adjusted_at = DateTime.new(2012,5,5,0,0,0)
    @mutated_at = DateTime.new(2012,10,5,0,0,0)
    
    
    @quantity = 5 
    @sa = StockAdjustment.create_object(
      :adjusted_at  => @adjusted_at,  
      :warehouse_id => @wh_1.id ,  
      :description  => "The adjustment description",  
      :code         => "ADJ234" 
    )
    
    @sae = StockAdjustmentEntry.create_object(
      :stock_adjustment_id => @sa.id ,
      :item_id => @item_1.id ,
      :actual_quantity => @quantity
    )
    @sae_2 = StockAdjustmentEntry.create_object(
      :stock_adjustment_id => @sa.id ,
      :item_id => @item_2.id ,
      :actual_quantity => @quantity
    )
    
    @sa.reload
    @sa.confirm 
    @item_1.reload 
    @wh_item_1 = WarehouseItem.find_or_create_object(
      :warehouse_id => @wh_1.id , 
      :item_id => @item_1.id 
    )
  end
   
  it 'should have wh_item_1' do
    @wh_item_1.should be_valid 
    
    @item_1.ready.should == @quantity
    @wh_item_1.ready.should == @quantity 
  end
  
  it 'should be allowed to create warehouse mutation' do
    @wm = WarehouseMutation.create_object(
      :mutated_at          =>  @mutated_at  ,            
      :source_warehouse_id => @wh_1.id    ,              
      :target_warehouse_id =>   @wh_2.id ,               
      :description         =>   "awesome description" ,  
      :code                =>"WM234234"                  
    )
    
    @wm.should be_valid 
  end
  
  it 'should not create warehouse mutation if source == target warehouse' do
    @wm = WarehouseMutation.create_object(
      :mutated_at          =>  @mutated_at  ,            
      :source_warehouse_id => @wh_1.id    ,              
      :target_warehouse_id =>   @wh_1.id ,               
      :description         =>   "awesome description" ,  
      :code                =>"WM234234"                  
    )
    
    @wm.should_not be_valid
  end
  
  it 'should not create warehouse mutation if source or target is nil' do
    @wm = WarehouseMutation.create_object(
      :mutated_at          =>  @mutated_at  ,            
      :source_warehouse_id => @wh_1.id    ,              
      :target_warehouse_id =>    nil ,               
      :description         =>   "awesome description" ,  
      :code                =>"WM234234"                  
    )
    
    @wm.should_not be_valid
    
    @wm = WarehouseMutation.create_object(
      :mutated_at          =>  @mutated_at  ,            
      :source_warehouse_id =>  nil    ,              
      :target_warehouse_id =>   @wh_1.id ,               
      :description         =>   "awesome description" ,  
      :code                =>"WM234234"                  
    )
    
    @wm.should_not be_valid
  end
  
  context "creation of warehouse mutation" do
    before(:each) do
      @wm = WarehouseMutation.create_object(
        :mutated_at          =>  @mutated_at  ,            
        :source_warehouse_id => @wh_1.id    ,              
        :target_warehouse_id =>   @wh_2.id ,               
        :description         =>   "awesome description" ,  
        :code                =>"WM234234"                  
      )
    end
    
    it 'should allow update' do
      @wm.update_object(
        :mutated_at          =>  @mutated_at  ,            
        :source_warehouse_id => @wh_1.id    ,              
        :target_warehouse_id =>   @wh_2.id ,               
        :description         =>   "awesome description hahaha" ,  
        :code                =>"WM234234"                  
      )
      @wm.should be_valid
      
      @wm.update_object(
        :mutated_at          =>  @mutated_at  ,            
        :source_warehouse_id => @wh_1.id    ,              
        :target_warehouse_id =>   @wh_1.id ,               
        :description         =>   "awesome description hahaha" ,  
        :code                =>"WM234234"                  
      )
      @wm.should_not be_valid # because source == target 
      @wm.errors.size.should_not == 0 
    end
    
    it 'should allow deletion' do
      @wm.delete_object
      @wm.persisted?.should be_false 
    end
    
    it 'should not allow confirm' do
      @wm.confirm
      @wm.errors.size.should_not == 0 
      @wm.is_confirmed.should be_false 
    end
    
    it 'should allow creation of @wme' do
      @wme = WarehouseMutationEntry.create_object(
        :item_id               => @item_1.id,  
        :warehouse_mutation_id => @wm.id ,   
        :quantity              =>  @item_1.ready - 1  
      )
      
      @wme.should be_valid 
    end
    
  end
  
end
