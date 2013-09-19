require 'spec_helper'

describe SalesDeliveryEntry do
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
    
    
    
  end
  
  
  
  
  context "ready quantity > sold quantity" do
    before(:each) do
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

      @delivered_quantity = 2
    end
    
    # summary
    # purchased quantity = 10 
    # received quantity = 8 
    # sold quantity = 5
    # delivered quantity = 2 

    it 'should create sde' do
      @sde = SalesDeliveryEntry.create_object(
        :sales_delivery_id => @sd.id, 
        :sales_order_entry_id => @soe.id ,
        :quantity => @delivered_quantity
      )

      @sde.should be_valid 
    end

    it 'should not allow sde if no quantity or quantity is more than sold' do
      @sde = SalesDeliveryEntry.create_object(
        :sales_delivery_id => @sd.id, 
        :sales_order_entry_id => @soe.id ,
        :quantity => 0
      )
      @sde.should_not be_valid 

      @sde = SalesDeliveryEntry.create_object(
        :sales_delivery_id => @sd.id, 
        :sales_order_entry_id => @soe.id ,
        :quantity => @soe_quantity +  1 
      )

      @sde.should_not be_valid  
    end

    context "creating the sde" do
      before(:each) do
        @sde = SalesDeliveryEntry.create_object(
          :sales_delivery_id => @sd.id, 
          :sales_order_entry_id => @soe.id ,
          :quantity => @delivered_quantity
        )
      end

      it 'should be valid sde' do
        @sde.should be_valid 
      end

      it 'should be updatable' do
        @sde.update_object(
          :sales_delivery_id => @sd.id, 
          :sales_order_entry_id => @soe.id ,
          :quantity => 1 
        )
        @sde.errors.size.should == 0 
        @sde.should be_valid 
      end

      it 'should be deletable' do
        @sde.delete_object
        @sde.persisted?.should be_false 
      end
      
      context "confirm the sd" do
        before(:each) do
          @sd.reload
          @item_1.reload 
          @soe.reload 
          @initial_item_1_ready = @item_1.ready 
          @initial_item_1_pending_delivery = @item_1.pending_delivery 
          @initial_soe_pending_delivery = @soe.pending_delivery
          @sd.confirm 
          
          @sde.reload 
          @item_1.reload 
          @soe.reload 
        end
        
        it 'should confirm the sd and sde' do
          @sd.is_confirmed.should be_true 
          @sde.is_confirmed.should be_true 
        end
        
        it 'should reduce the ready item by the amount of delivered item' do
          final_item_1_ready = @item_1.ready 
          final_item_1_pending_delivery = @item_1.pending_delivery 
          final_soe_pending_delivery = @soe.pending_delivery 
          
          diff_item_1_ready = final_item_1_ready - @initial_item_1_ready
          diff_item_1_pending_delivery = final_item_1_pending_delivery - @initial_item_1_pending_delivery
          diff_soe_pending_delivery = final_soe_pending_delivery - @initial_soe_pending_delivery
          
          diff_item_1_ready.should == -1*@delivered_quantity 
          diff_item_1_pending_delivery.should == -1*@delivered_quantity
          diff_soe_pending_delivery.should == -1*@delivered_quantity
        end
        
        it 'should create 2 stock mutations: to deduct pending_delivery, and to deduct_ready' do
          @sde.stock_mutations.count.should == 2 
          @deduct_pending_delivery_sm = @sde.stock_mutations.where(:case => STOCK_MUTATION_CASE[:pending_delivery]).first 
          @deduct_ready_sm = @sde.stock_mutations.where(:case => STOCK_MUTATION_CASE[:ready]).first 
          
          @deduct_pending_delivery_sm.warehouse_id.should == @wh_1.id 
          @deduct_pending_delivery_sm.quantity.should == -1*@sde.quantity
          @deduct_ready_sm.quantity.should == -1*@sde.quantity 
        end
        
        it 'should not allow delete' do
          @sde.delete_object
          @sde.errors.size.should_not == 0 
          @sde.persisted?.should be_true 
        end
        
        it 'should not allow update ' do
          @sde.update_object(
            :sales_delivery_id => @sd.id, 
            :sales_order_entry_id => @soe.id ,
            :quantity => 3
          )
          @sde.errors.size.should_not == 0   
        end
        
        context "unconfirm" do
          before(:each) do
            @sd.reload 
            @sd.unconfirm
            @sde.reload
            @item_1.reload 
          end
          
          it 'should unconfirm the sd + sde' do
            @sd.is_confirmed.should be_false
            @sde.is_confirmed.should be_false 
          end
          
          it 'should be deletable' do
            @sde.delete_object
            @sde.persisted?.should be_false 
          end
          
          it 'should be updatable' do
            @sde.update_object(
              :sales_delivery_id => @sd.id, 
              :sales_order_entry_id => @soe.id ,
              :quantity => 3
            )
            
            @sde.errors.size.should == 0 
            @sde.should be_valid 
          end
        end
      end
    end
  end
  
  
  
  
  # corner cases
  context "ready quantity < sold quantity (pending delivery)" do
    before(:each) do
      @prec = PurchaseReceival.create_object(
        :supplier_id => @supplier.id ,
        :received_at => @received_at ,
        :code => @receive_code
      ) 

      @received_quantity = 5
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

      @soe_quantity = 8
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

      @delivered_quantity = @received_quantity +  1
    end
    
    it 'should not allow sde if delivered quantity > ready quantity' do
      @sde = SalesDeliveryEntry.create_object(
        :sales_delivery_id => @sd.id, 
        :sales_order_entry_id => @soe.id ,
        :quantity => @delivered_quantity
      )
      
      @sde.should_not be_valid 
    end
  end
  
  
   
end
