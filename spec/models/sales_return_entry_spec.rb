require 'spec_helper'

describe SalesReturnEntry do
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
    
    @sret = SalesReturn.create_object(
      :customer_id => @customer.id , 
      :received_at => @returned_at, 
      :code        => "SRET32423",
      :warehouse_id => @wh_1.id
    )
    @returned_quantity  = 1
  end
  
  it 'should allow sales return entry creation' do
    @sret_e = SalesReturnEntry.create_object(
      :sales_return_id      => @sret.id ,  
      :sales_order_entry_id => @soe.id ,  
      :quantity             => @returned_quantity   
    )
    
    @sret_e.should be_valid 
  end
  
  it 'should not allow quantity > delivered quantity or quantity <= 0 ' do
    @sret_e = SalesReturnEntry.create_object(
      :sales_return_id      => @sret.id ,  
      :sales_order_entry_id => @soe.id ,  
      :quantity             => @delivered_quantity + 1  
    )
    
    @sret_e.should_not be_valid
    
    @sret_e = SalesReturnEntry.create_object(
      :sales_return_id      => @sret.id ,  
      :sales_order_entry_id => @soe.id ,  
      :quantity             => 0 
    )
    
    @sret_e.should_not be_valid
  end
  
  context "creating sales return entry" do
    before(:each) do
      @sret_e = SalesReturnEntry.create_object(
        :sales_return_id      => @sret.id ,  
        :sales_order_entry_id => @soe.id ,  
        :quantity             => @returned_quantity   
      )
    end
    
    it 'should create valid sret_e' do
      @sret_e.should be_valid 
    end
    
    it 'should be deletable' do
      @sret_e.delete_object
      @sret_e.persisted?.should be_false 
    end
    
    it 'should be updatable' do
      @sret_e.update_object(
        :sales_return_id      => @sret.id ,  
        :sales_order_entry_id => @soe.id ,  
        :quantity             =>   1
      )
      
      @sret_e.errors.size.should == 0 
      @sret_e.should be_valid 
    end
    
    context 'confirm the sales return' do
      before(:each) do
        @sret.reload 
        @item_1.reload 
        @soe.reload 
        @wh_item_1 = WarehouseItem.find_or_create_object(
          :warehouse_id => @wh_1.id , 
          :item_id => @item_1.id 
        )
        @initial_item_1_pending_delivery = @item_1.pending_delivery
        @initial_item_1_ready = @item_1.ready 
        @initial_soe_pending_delivery = @soe.pending_delivery
        @initial_soe_delivered = @soe.delivered 
        @initial_wh_item_1_pending_delivery = @wh_item_1.pending_delivery
        @initial_wh_item_1_ready = @wh_item_1.ready 
        
        @sret.confirm
        @sret_e.reload 
        @soe.reload 
        @item_1.reload 
        @wh_item_1.reload 
        
        @final_item_1_pending_delivery = @item_1.pending_delivery
        @final_item_1_ready = @item_1.ready 
        @final_soe_pending_delivery = @soe.pending_delivery
        @final_soe_delivered = @soe.delivered 
        @final_wh_item_1_pending_delivery = @wh_item_1.pending_delivery
        @final_wh_item_1_ready = @wh_item_1.ready
      end
      
      
      it 'should create 2 stock mutations' do
        @sret_e.stock_mutations.count.should ==  2
        @deduct_pending_delivery_sm = @sret_e.stock_mutations.where(:case => STOCK_MUTATION_CASE[:pending_delivery]).first
        @deduct_ready_sm = @sret_e.stock_mutations.where(:case => STOCK_MUTATION_CASE[:ready]).first
        
        @deduct_pending_delivery_sm.quantity.should == @returned_quantity
        @deduct_ready_sm.quantity.should == @returned_quantity
      end
      
      
      it 'should ensure the stock mutation changes is correct' do
        diff_item_1_pending_delivery    = @final_item_1_pending_delivery - @initial_item_1_pending_delivery
        diff_item_1_ready               = @final_item_1_ready  - @initial_item_1_ready
        diff_soe_pending_delivery       = @final_soe_pending_delivery - @initial_soe_pending_delivery
        diff_soe_delivered              = @final_soe_delivered - @initial_soe_delivered
        diff_wh_item_1_pending_delivery = @final_wh_item_1_pending_delivery - @initial_wh_item_1_pending_delivery
        diff_wh_item_1_ready            = @final_wh_item_1_ready - @initial_wh_item_1_ready
        
        
        
        diff_item_1_pending_delivery    .should == @returned_quantity
        diff_item_1_ready               .should == @returned_quantity
        diff_soe_pending_delivery       .should == @returned_quantity
        diff_soe_delivered              .should == -1*@returned_quantity
        diff_wh_item_1_pending_delivery .should == @returned_quantity
        diff_wh_item_1_ready            .should == @returned_quantity
        
        
      end
      
      it 'should confirm sret' do
        @sret.is_confirmed.should be_true 
        @sret_e.is_confirmed.should be_true 
      end
      
      it 'should not allow deletion' do
        @sret_e.delete_object
        @sret_e.persisted?.should be_true 
      end
      
      it 'should not allow update object' do
        @sret_e.update_object(
          :sales_return_id      => @sret.id ,  
          :sales_order_entry_id => @soe.id ,  
          :quantity             =>   2
        )
        
        @sret_e.errors.size.should_not == 0
      end
      
      context "unconfirm" do
        before(:each) do
          @soe.reload 
          @sret_e.reload 
          @item_1.reload
          @wh_item_1.reload
          
          
          @initial_item_1_pending_delivery = @item_1.pending_delivery
          @initial_item_1_ready = @item_1.ready 
          @initial_soe_pending_delivery = @soe.pending_delivery
          @initial_soe_delivered = @soe.delivered 
          @initial_wh_item_1_pending_delivery = @wh_item_1.pending_delivery
          @initial_wh_item_1_ready = @wh_item_1.ready
          
          
          @sret.reload
          @sret.unconfirm 
          @soe.reload 
          @sret_e.reload 
          @item_1.reload
          @wh_item_1.reload 
          
          @final_item_1_pending_delivery = @item_1.pending_delivery
          @final_item_1_ready = @item_1.ready 
          @final_soe_pending_delivery = @soe.pending_delivery
          @final_soe_delivered = @soe.delivered 
          @final_wh_item_1_pending_delivery = @wh_item_1.pending_delivery
          @final_wh_item_1_ready = @wh_item_1.ready
        end
        
        it 'should ensure the stock mutation changes is correct' do
          diff_item_1_pending_delivery    = @final_item_1_pending_delivery - @initial_item_1_pending_delivery
          diff_item_1_ready               = @final_item_1_ready  - @initial_item_1_ready
          diff_soe_pending_delivery       = @final_soe_pending_delivery - @initial_soe_pending_delivery
          diff_soe_delivered              = @final_soe_delivered - @initial_soe_delivered
          diff_wh_item_1_pending_delivery = @final_wh_item_1_pending_delivery - @initial_wh_item_1_pending_delivery
          diff_wh_item_1_ready            = @final_wh_item_1_ready - @initial_wh_item_1_ready



          diff_item_1_pending_delivery    .should == -1*@returned_quantity
          diff_item_1_ready               .should == -1*@returned_quantity
          diff_soe_pending_delivery       .should == -1*@returned_quantity
          diff_soe_delivered              .should == -1*-1*@returned_quantity
          diff_wh_item_1_pending_delivery .should == -1*@returned_quantity
          diff_wh_item_1_ready            .should == -1*@returned_quantity


        end
        
        it 'should produce 0 stock mutations' do
          @sret_e.stock_mutations.count.should == 0 
        end
      end
    end
  end
   
end
