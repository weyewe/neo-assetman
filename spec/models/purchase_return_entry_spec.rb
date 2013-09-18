require 'spec_helper'

describe PurchaseReturnEntry do
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
    
    
    @purchased_at = DateTime.new(2012,10,5,0,0,0)
    @received_at  = DateTime.new( 2012,12,5,0,0,0)
    @returned_at = DateTime.new( 2013,1,5,0,0,0)
    
    
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
    @po.reload
    @poe.reload 
    @prec = PurchaseReceival.create_object(
      :supplier_id => @supplier.id ,
      :received_at => @received_at,
      :code => "REC3424"
    )
    
    @received_quantity = 2
    @prec_e = PurchaseReceivalEntry.create_object(
      :purchase_receival_id => @prec.id ,
      :purchase_order_entry_id => @poe.id,
      :quantity => @received_quantity ,
      :supplier_id => @supplier.id 
    )
    
    
    @poe.reload
    @initial_poe_pending_receival = @poe.pending_receival
    @initial_poe_received = @poe.received
    
    @prec.confirm 
    
    @po.reload
    @poe.reload 
    @prec_e.reload
    
    
    @return_code = "RET2342"
    @pret = PurchaseReturn.create_object(
      :supplier_id => @supplier.id ,
      :received_at => @returned_at ,
      :code => @return_code
    )
  end
  
  
  it 'should produced sane setup' do
    @po.should be_valid
    @poe.should be_valid 
    @prec_e.should be_valid 
    @prec.should be_valid
    @prec.is_confirmed.should be_true 
    
    
    final_poe_pending_receival = @poe.pending_receival
    final_poe_received = @poe.received
    
    diff_pending_receival  = final_poe_pending_receival - @initial_poe_pending_receival
    diff_received = final_poe_received - @initial_poe_received
    
    diff_pending_receival.should == -1*( @received_quantity)
    diff_received.should == @received_quantity
    
    @pret.should be_valid 
  end
  
  it 'should be allowed to create purchase return as long as the quantity is less than received quantity' do
    received_quantity = @poe.received 
    @pret_e = PurchaseReturnEntry.create_object(
      :purchase_return_id => @pret.id ,
      :purchase_order_entry_id => @poe.id,
      :quantity => received_quantity 
    )
    
    @pret_e.should be_valid 
    
  end
  
  it 'should not create purchase return entry if the quantity returned > quantity received' do
    received_quantity = @poe.received 
    @pret_e = PurchaseReturnEntry.create_object(
      :purchase_return_id => @pret.id ,
      :purchase_order_entry_id => @poe.id,
      :quantity => received_quantity  + 1 
    )
    
    @pret_e.should_not be_valid
    
    @pret_e = PurchaseReturnEntry.create_object(
      :purchase_return_id => @pret.id ,
      :purchase_order_entry_id => @poe.id,
      :quantity =>  0
    )
    
    @pret_e.should_not be_valid
  end
  
  context "created purchase return entry" do
    before(:each) do
      @returned_quantity = @received_quantity - 1
      @pret_e = PurchaseReturnEntry.create_object(
        :purchase_return_id => @pret.id ,
        :purchase_order_entry_id => @poe.id,
        :quantity => @returned_quantity 
      )
      
    end
    
    it 'should create valid purchase return entry' do
      @pret_e.should be_valid 
    end
    
    it 'should be updatable' do
      @pret_e.update_object(
        :purchase_return_id => @pret.id ,
        :purchase_order_entry_id => @poe.id,
        :quantity => @received_quantity 
      )
      
      @pret_e.should be_valid 
    end
    
    it 'should be deletable' do
      @pret_e.delete_object
      @pret_e.persisted?.should be_false 
    end
    
    context 'confirming the purchase return' do
      before(:each) do
        @poe.reload 
        @item_1.reload 
        @wh_item_1 = WarehouseItem.find_or_create_object(
          :warehouse_id => @pret_e.purchase_order_entry.purchase_order.warehouse_id ,
          :item_id => @item_1.id 
        )
        @initial_pending_receival = @poe.pending_receival
        @initial_received = @poe.received
        @initial_item_1_ready = @item_1.ready 
        @initial_item_1_pending_receival = @item_1.pending_receival
         
        @initial_wh_item_1_ready = @wh_item_1.ready
        @initial_wh_item_1_pending_receival = @wh_item_1.pending_receival  
        @pret.confirm
        @pret_e.reload 
        @poe.reload
        @wh_item_1.reload 
        @item_1.reload  
      end
      
      it 'should confirm the purchase return' do
        @pret.is_confirmed.should be_true 
      end
      
      it 'should reduce the received quantity and increase the pending receival' do
        final_pending_receival = @poe.pending_receival
        final_received = @poe.received 
        final_item_1_ready = @item_1.ready 
        final_wh_item_1_ready = @wh_item_1.ready 
        
        final_item_1_pending_receival = @item_1.pending_receival
        final_wh_item_1_pending_receival = @wh_item_1.pending_receival 
        
        diff_pending_receival           = final_pending_receival - @initial_pending_receival
        diff_received                   = final_received - @initial_received
        diff_item_1_ready               = final_item_1_ready - @initial_item_1_ready
        diff_wh_item_1_ready            = final_wh_item_1_ready - @initial_wh_item_1_ready
        diff_item_1_pending_receival    = final_item_1_pending_receival - @initial_item_1_pending_receival
        diff_wh_item_1_pending_receival = final_wh_item_1_pending_receival - @initial_wh_item_1_pending_receival

        
        diff_pending_receival          .should == @returned_quantity
        diff_received                  .should == -1*@returned_quantity
        diff_item_1_ready              .should == -1*@returned_quantity
        diff_wh_item_1_ready           .should == -1*@returned_quantity
        diff_item_1_pending_receival   .should == @returned_quantity
        diff_wh_item_1_pending_receival.should == @returned_quantity
      end
      
      it 'should not be updatable' do
        @pret_e.update_object(
          :purchase_return_id => @pret.id ,
          :purchase_order_entry_id => @poe.id,
          :quantity => 1
        )
        
        @pret_e.errors.size.should_not == 0 
      end
      
      it 'should not deletable' do
        @pret_e.delete_object
        @pret_e.persisted?.should be_true  
      end
      
      context 'unconfirm the purchase return' do
        before(:each) do
          @pret_e.reload 
          @poe.reload
          @wh_item_1.reload 
          @item_1.reload
          
          @initial_pending_receival = @poe.pending_receival
          @initial_received = @poe.received
          @initial_item_1_ready = @item_1.ready 
          @initial_item_1_pending_receival = @item_1.pending_receival
          @initial_wh_item_1_ready = @wh_item_1.ready
          @initial_wh_item_1_pending_receival = @wh_item_1.pending_receival
          
          
          
          @pret.unconfirm 
          @pret_e.reload 
          @poe.reload
          @wh_item_1.reload 
          @item_1.reload 
        end
        
        it 'should increase the received quantity and reduce the pending receival' do
          final_pending_receival = @poe.pending_receival
          final_received = @poe.received 
          final_item_1_ready = @item_1.ready 
          final_wh_item_1_ready = @wh_item_1.ready 

          final_item_1_pending_receival = @item_1.pending_receival
          final_wh_item_1_pending_receival = @wh_item_1.pending_receival 

          diff_pending_receival           = final_pending_receival - @initial_pending_receival
          diff_received                   = final_received - @initial_received
          diff_item_1_ready               = final_item_1_ready - @initial_item_1_ready
          diff_wh_item_1_ready            = final_wh_item_1_ready - @initial_wh_item_1_ready
          diff_item_1_pending_receival    = final_item_1_pending_receival - @initial_item_1_pending_receival
          diff_wh_item_1_pending_receival = final_wh_item_1_pending_receival - @initial_wh_item_1_pending_receival


          diff_pending_receival          .should == -1*@returned_quantity
          diff_received                  .should == @returned_quantity
          diff_item_1_ready              .should == @returned_quantity
          diff_wh_item_1_ready           .should == @returned_quantity
          diff_item_1_pending_receival   .should == -1*@returned_quantity
          diff_wh_item_1_pending_receival.should == -1*@returned_quantity
        end
        
        it 'should be updatable' do
          @pret_e.update_object(
            :purchase_return_id => @pret.id ,
            :purchase_order_entry_id => @poe.id,
            :quantity => 1 
          )
          
          @pret_e.errors.size.should ==0  
          @pret_e.should be_valid 
          
        end
        
        it 'should be deletable' do
          @pret_e.delete_object
          @pret_e.persisted?.should be_false 
        end
        
        
      end
    end
  end
  
end
