require 'spec_helper'

describe SalesDelivery do
  before(:each) do
    @wh_1 = Warehouse.create_object(
      :name => "Warehouse 1",
      :description => "Our main warehouse"
    )
    
    @wh_2 = Warehouse.create_object(
      :name => "Warehouse 2",
      :description => "Our first mobile warehouse"
    )
    
    @item_1 = Item.create_object(
      :name => "Hose 5m",
      :code => "HS34"
    )
    
    @item_2 = Item.create_object(
      :name => "2Hose 5m",
      :code => "2HS34"
    )
    
    @supplier = Supplier.create_object(
      :name => "Supplier 1 "
    )
    
    @customer = Customer.create_object(
      :name => "Customer 1 "
    )
    
    
    @purchased_at = DateTime.new(2012,10,5,0,0,0)
    @received_at  = DateTime.new( 2012,12,5,0,0,0)
    @returned_at = DateTime.new( 2013,1,5,0,0,0)
    @sold_at = DateTime.new( 2013,2,5,0,0,0)
    @delivered_at  = DateTime.new( 2013,3,5,0,0,0)
    
    @po = PurchaseOrder.create_object(
      :supplier_id => @supplier.id ,
      :warehouse_id => @wh_1.id ,
      :description => "The description",
      :code => "PO1234",
      :purchased_at => @purchased_at
    )
    
    @quantity = 5 
    @poe = PurchaseOrderEntry.create_object(
      :purchase_order_id => @po.id ,
      :item_id => @item_1.id ,
      :quantity => @quantity
    )
    @po.confirm 
    @poe.reload 
    @receive_code = 'REC1344'
    
    @prec = PurchaseReceival.create_object(
      :supplier_id => @supplier.id ,
      :received_at => @received_at ,
      :code => @receive_code
    ) 
    
    @received_quantity = 4
    @prec_e = PurchaseReceivalEntry.create_object(
      :purchase_receival_id => @prec.id ,
      :purchase_order_entry_id => @poe.id,
      :quantity => @received_quantity ,
      :supplier_id => @supplier.id 
    )
    
    @prec.confirm 
    
    @po.reload
    @poe.reload 
    @prec_e.reload
    @item_1.reload 
    
    
    @so = SalesOrder.create_object(
      :customer_id => @customer.id, 
      :sold_at => @sold_at, 
      :description => "awesome",
      :code => "SO23424"
    )
    
    @soe_quantity = 5 
    @soe=  SalesOrderEntry.create_object(
      :sales_order_id => @so.id , 
      :quantity => @soe_quantity,
      :item_id => @item_1.id  
    )
    @so.reload 
    @so.confirm 
    @soe.reload 
    @item_1.reload 
  end
  
  it 'should confirm so and soe' do
    @soe.is_confirmed.should be_true 
    @so.is_confirmed.should be_true 
    @item_1.pending_delivery.should == @soe_quantity
    @item_1.ready.should == @received_quantity
  end
  
  it 'should allow sd creation' do
    @sd = SalesDelivery.create_object(
      :customer_id  =>@customer.id,
      :delivered_at =>@delivered_at, 
      :warehouse_id =>@wh_1.id,
      :code         => "DEL14234"
    )
    
    @sd.should be_valid 
  end
  
  it 'should not create sd without warehouse or customer' do
    @sd = SalesDelivery.create_object(
      :customer_id  =>nil,
      :delivered_at =>@delivered_at, 
      :warehouse_id =>@wh_1.id,
      :code         => "DEL14234"
    )
    @sd.should_not be_valid 
    @sd.errors.size.should_not == 0 
    
    @sd = SalesDelivery.create_object(
      :customer_id  =>@customer.id,
      :delivered_at =>@delivered_at, 
      :warehouse_id =>nil ,
      :code         => "DEL14234"
    )
    @sd.should_not be_valid 
    @sd.errors.size.should_not == 0
  end
  
  context "creating sd" do
    before(:each) do
      @sd = SalesDelivery.create_object(
        :customer_id  =>@customer.id,
        :delivered_at =>@delivered_at, 
        :warehouse_id =>@wh_1.id,
        :code         => "DEL14234"
      )
    end
    
    it 'should create sd' do
      @sd.should be_valid 
    end
    
    it 'should allow delete' do
      @sd.delete_object
      @sd.persisted?.should be_false 
    end
    
    it 'should allow update' do
      @sd.update_object(
        :customer_id  =>@customer.id,
        :delivered_at =>@delivered_at, 
        :warehouse_id =>@wh_2.id,
        :code         => "DEL14234"
      )
      
      @sd.errors.size.should == 0 
      @sd.should be_valid 
    end
    
    it 'should not allow confirmation' do
      @sd.confirm
      @sd.is_confirmed.should be_false
      @sd.errors.size.should_not == 0 
    end
    
  end
end
