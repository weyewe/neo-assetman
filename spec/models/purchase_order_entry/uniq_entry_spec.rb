require 'spec_helper'

describe PurchaseOrder do
  before(:each) do
    @wh_1 = Warehouse.create_object(
      :name => "Warehouse 1",
      :description => "Our main warehouse"
    )
    
    @item_1 = Item.create_object(
      :name => "Hose 5m",
      :code => "HS34"
    )
    
    @item_2 = Item.create_object(
      :name => "Hose 10M",
      :code => "HS3455"
    )
    
    @supplier = Supplier.create_object(
      :name => "Supplier 1 "
    )
    
    @po = PurchaseOrder.create_object(
      :supplier_id => @supplier.id ,
      :warehouse_id => @wh_1.id ,
      :description => "The description",
      :code => "PO1234"
    )
    
    
    @poe = PurchaseOrderEntry.create_object(
      :purchase_order_id => @po.id ,
      :item_id => @item_1.id ,
      :quantity =>  5
    )
    
    
    
    
  end 
  
  it 'should creaet valid poe and po' do
    @po.should be_valid
    @poe.should be_valid 
  end
  
  it 'should create total count == 1' do
    @po.purchase_order_entries.count.should == 1 
  end
  
  it 'should not count non persisted object' do
    @poe2 = PurchaseOrderEntry.new 
    @poe2.purchase_order_id = @po.id 
    @poe2.item_id = @item_1.id 
    @poe2.quantity = 5 
    
    @poe2.persisted?.should be_false 
    @po.purchase_order_entries.count.should == 1
    
    PurchaseOrderEntry.count.should == 1
  end
  
  
  it 'should prevent creation with similar item' do
    @poe2 = PurchaseOrderEntry.create_object(
      :purchase_order_id => @po.id ,
      :item_id => @item_1.id ,
      :quantity =>  5
    )
    
    @poe2.errors.size.should_not == 0 
  end
  
  context 'creating poe_2' do
    before(:each) do
      @poe2 = PurchaseOrderEntry.create_object(
        :purchase_order_id => @po.id ,
        :item_id => @item_2.id ,
        :quantity =>  5
      )
      
    end
    
    it 'shoudl create poe 2' do
      @poe2.should be_valid
    end
    
    it 'should prevent update to item_1' do
      @poe2 .update_object(
        :purchase_order_id => @po.id ,
        :item_id => @item_1.id ,
        :quantity =>  5
      )
      
      @poe2.errors.size.should_not == 0 
    end
  end 
  
  
  
  
  
  
  
end
