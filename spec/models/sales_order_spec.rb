require 'spec_helper'

describe SalesOrder do
  before(:each) do
    @wh_1 = Warehouse.create_object(
      :name => "Warehouse 1",
      :description => "Our main warehouse"
    )
    
    @item_1 = Item.create_object(
      :name => "Hose 5m",
      :code => "HS34"
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
    
    @received_quantity = 2
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
  end
  
  it 'should produce ready item' do
    @item_1.ready.should > 0 
  end
  
  it 'should allow sales order creation' do
    @so = SalesOrder.create_object(
      :customer_id => @customer.id, 
      :sold_at => @sold_at, 
      :description => "awesome",
      :code => "SO23424"
    )
     
    @so.should be_valid 
  end
  
  
  
  context "creating the so" do
    before(:each) do
      @so = SalesOrder.create_object(
        :customer_id => @customer.id, 
        :sold_at => @sold_at, 
        :description => "awesome",
        :code => "SO23424"
      )
    end
    
    it 'should create sales order' do
      @so.should be_valid
    end
    
    it 'should be deletable' do
      @so.delete_object
      @so.persisted?.should be_false
    end

    it 'should be updatable' do
      @so.update_object(
        :customer_id => @customer.id, 
        :sold_at => @sold_at, 
        :description => "awesome 2",
        :code => "SO23424"
      )

      @so.errors.size.should  == 0 
    end
    
    it 'should NOT confirm sales order' do
      @so.confirm
      @so.errors.size.should_not == 0 
      @so.is_confirmed.should be_false 
    end
    
    it 'should allow sales order entry creation' do
      @soe_quantity = 5 
      @soe=  SalesOrderEntry.create_object(
        :sales_order_id => @so.id , 
        :quantity => @soe_quantity,
        :item_id => @item_1.id  
      )
      
      @soe.should be_valid 
    end
    
    context "creating the soe" do
      before(:each) do
        @soe_quantity = 5 
        @soe=  SalesOrderEntry.create_object(
          :sales_order_id => @so.id , 
          :quantity => @soe_quantity,
          :item_id => @item_1.id  
        )
      end
      
      it 'should create soe' do
        @soe.should be_valid 
      end
      
      it 'should not allow so deletion if there is soe' do
        @so.delete_object
        @so.persisted?.should be_true 
        @so.errors.size.should_not == 0 
      end
    end
  end
end
