require 'spec_helper'

describe SalesOrderEntry do
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
    
    
    @so = SalesOrder.create_object(
      :customer_id => @customer.id, 
      :sold_at => @sold_at, 
      :description => "awesome",
      :code => "SO23424"
    )
  end
  
  
  it 'should allow soe creation' do
    @soe_quantity = 5 
    @soe=  SalesOrderEntry.create_object(
      :sales_order_id => @so.id , 
      :quantity => @soe_quantity,
      :item_id => @item_1.id  
    )
    
    @soe.should be_valid 
  end
  
  it 'should not allow soe creation if there is no quantity' do
    @soe=  SalesOrderEntry.create_object(
      :sales_order_id => @so.id , 
      :quantity => 0,
      :item_id => @item_1.id  
    )
    @soe.should_not be_valid 
    
    @soe=  SalesOrderEntry.create_object(
      :sales_order_id => @so.id , 
      :quantity => -1,
      :item_id => @item_1.id  
    )
    @soe.should_not be_valid 
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
    
    it 'should be updatable' do
      @soe.update_object(
        :sales_order_id => @so.id , 
        :quantity => 0,
        :item_id => @item_1.id  
      )
      @soe.errors.size.should_not == 0 
      
      @new_soe_quantity = 3 
      @soe.update_object(
        :sales_order_id => @so.id , 
        :quantity => @new_soe_quantity,
        :item_id => @item_1.id  
      )
      @soe.should be_valid 
      @soe.pending_delivery.should == @new_soe_quantity
    end

    it 'should be deletable ' do
      @soe.delete_object
      @soe.persisted?.should be_false 
    end
    
    it 'should allow another soe with same item_id' do
      @soe_quantity = 5 
      @soe2 =  SalesOrderEntry.create_object(
        :sales_order_id => @so.id , 
        :quantity => @soe_quantity,
        :item_id => @item_1.id  
      )
      
      @soe2.should_not be_valid 
      @soe2.errors.size.should_not == 0 
    end
    
    context "creation of another sales order entry, to test that update to similar soe is imposible" do
      before(:each) do
        @soe_quantity = 5 
        @soe2 =  SalesOrderEntry.create_object(
          :sales_order_id => @so.id , 
          :quantity => @soe_quantity,
          :item_id => @item_2.id  
        )
      end
      
      it 'should create soe2' do
        @soe2.should be_valid 
      end
      
      it 'should not allow item update to another item already in the SO list' do 
        @soe2.update_object(
          :sales_order_id => @so.id , 
          :quantity => @soe_quantity,
          :item_id => @item_1.id
        )
        
        @soe2.should_not be_valid
        @soe2.errors.size.should_not == 0 
      end
      
      it 'should allow self update' do
         @soe2.update_object(
            :sales_order_id => @so.id , 
            :quantity => 8,
            :item_id => @item_2.id
          )

          @soe2.should be_valid 
      end
    end
    
    context "confirming the sales order" do
      before(:each) do
        @item_1.reload 
        @initial_item_1_pending_delivery = @item_1.pending_delivery 
        @so.confirm 
        
        @item_1.reload
        @soe.reload 
      end
      
      it 'should confirm sales order' do
        @so.is_confirmed.should be_true 
        @soe.is_confirmed.should be_true 
      end
      
      it 'should increase item pending delivery' do
        final_item_1_pending_delivery = @item_1.pending_delivery 
        
        diff_item_1_pending_delivery = final_item_1_pending_delivery - @initial_item_1_pending_delivery
        diff_item_1_pending_delivery.should == @soe_quantity
      end
      
      it 'should increase pending delivery' do
        @item_1.pending_delivery.should_not == 0 
      end
      
      it 'should create 1 stock mutation' do
        @soe.stock_mutation.should be_valid 
        @soe.stock_mutation.case.should == STOCK_MUTATION_CASE[:pending_delivery]
        @soe.stock_mutation.quantity.should == @soe.quantity 
        @soe.stock_mutation.warehouse.should be_nil 
      end
      
      it 'should not be deletable' do
        @soe.delete_object
        @soe.persisted?.should be_true 
        @soe.errors.size.should_not == 0
      end
      
      it 'should not be updatable' do
        @soe.update_object(
            :sales_order_id => @so.id , 
            :quantity => 8,
            :item_id => @item_2.id
          )
        @soe.errors.size.should_not == 0 
        # @soe.should_not be_valid 
      end
      
      context "unconfirm" do
        before(:each) do
          @item_1.reload 
          @soe.reload 
          @so.reload 
          
          @initial_item_1_pending_delivery = @item_1.pending_delivery 
          @so.unconfirm
          
          @item_1.reload
          @soe.reload 
        end
        
        
        it 'should unconfirm' do
          # puts "initial item_1 pending_delivery: #{@initial_item_1_pending_delivery}"
          # @so.errors.messages.each {|x| puts "msg: #{x}"}
          @so.errors.size.should  == 0 
          @so.is_confirmed.should be_false 
        end
        
        it 'should reduce the quantity of pending delivery' do
          final_item_1_pending_delivery = @item_1.pending_delivery 
          diff = final_item_1_pending_delivery - @initial_item_1_pending_delivery
          diff.should == -1*@soe_quantity
        end
        
        it 'should updatable' do
          @soe.update_object(
              :sales_order_id => @so.id , 
              :quantity => 8,
              :item_id => @item_2.id
            )
            
          @soe.errors.messages.each {|x| puts "msg: #{x}"}
          @soe.errors.size.should == 0 
          
        end
        
        it 'should deletable' do
          @soe.delete_object
          @soe.persisted?.should be_false 
        end
      end
      
    end
  end
  
  
end
