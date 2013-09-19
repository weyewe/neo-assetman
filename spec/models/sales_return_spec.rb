require 'spec_helper'

describe SalesReturn do
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
    @returned_at  = DateTime.new( 2013,3,10,0,0,0)
    
    @po = PurchaseOrder.create_object(
      :supplier_id => @supplier.id ,
      :warehouse_id => @wh_1.id ,
      :description => "The description",
      :code => "PO1234",
      :purchased_at => @purchased_at
    )
    
    @quantity = 10
    @poe = PurchaseOrderEntry.create_object(
      :purchase_order_id => @po.id ,
      :item_id => @item_1.id ,
      :quantity => @quantity
    )
    
    @poe_2 = PurchaseOrderEntry.create_object(
      :purchase_order_id => @po.id ,
      :item_id => @item_2.id ,
      :quantity => @quantity
    )
    @po.confirm 
    @poe.reload 
    @poe_2.reload 
    @receive_code = 'REC1344'
    
    @prec = PurchaseReceival.create_object(
      :supplier_id => @supplier.id ,
      :received_at => @received_at ,
      :code => @receive_code
    ) 

    @received_quantity = 8
    @prec_e = PurchaseReceivalEntry.create_object(
      :purchase_receival_id => @prec.id ,
      :purchase_order_entry_id => @poe.id,
      :quantity => @received_quantity ,
      :supplier_id => @supplier.id 
    )

    @prec_e_2 = PurchaseReceivalEntry.create_object(
      :purchase_receival_id => @prec.id ,
      :purchase_order_entry_id => @poe_2.id,
      :quantity => @received_quantity ,
      :supplier_id => @supplier.id 
    )

    @prec.confirm 

    @po.reload
    @poe.reload 
    @prec_e.reload
    @prec_e_2.reload 
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

    @soe_2 =  SalesOrderEntry.create_object(
      :sales_order_id => @so.id , 
      :quantity => @soe_quantity,
      :item_id => @item_2.id  
    )
    @so.reload 
    @so.confirm 
    @soe.reload 
    @soe_2.reload 
    @item_1.reload 

    @sd = SalesDelivery.create_object(
      :customer_id  =>@customer.id,
      :delivered_at =>@delivered_at, 
      :warehouse_id =>@wh_1.id,
      :code         => "DEL14234"
    )

    @delivered_quantity = 3
    
    @sde = SalesDeliveryEntry.create_object(
      :sales_delivery_id => @sd.id, 
      :sales_order_entry_id => @soe.id ,
      :quantity => @delivered_quantity
    )
    
    @sd.reload 
    @sd.confirm 
    @sde.reload 
    @soe.reload
  end
  
  
  it 'should confirm sd' do
    @sd.is_confirmed.should be_true 
  end
  
  it 'should create delivered sde' do
    @soe.delivered.should == @delivered_quantity 
  end
  
  it 'should be allowed to create sales return' do
    @sret = SalesReturn.create_object(
      :customer_id => @customer.id , 
      :received_at => @returned_at, 
      :code        => "SRET32423",
      :warehouse_id => @wh_1.id
    )
    
    
    @sret.should be_valid 
  end
  
  it 'should not create sales return if no customer_id' do
    @sret = SalesReturn.create_object(
      :customer_id => nil , 
      :received_at => @returned_at, 
      :code        => "SRET32423",
      :warehouse_id => @wh_1.id
    )
    
    
    @sret.should_not be_valid
  end
  
  context "created sales return" do
    before(:each) do
      @sret = SalesReturn.create_object(
        :customer_id => @customer.id , 
        :received_at => @returned_at, 
        :code        => "SRET32423",
        :warehouse_id => @wh_1.id
      )
    end
    
    it 'should create valid sales return ' do
      @sret.should be_valid 
    end
    
    it 'should not be confirmable' do
      @sret.confirm
      @sret.is_confirmed.should be_false 
      @sret.errors.size.should_not ==0  
    end
  end
   
   
end
