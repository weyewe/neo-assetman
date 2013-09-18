require 'spec_helper'

describe PurchaseReceivalEntry do
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
    
    @prec = PurchaseReceival.create_object(
      :supplier_id => @supplier.id ,
      :received_at => @received_at,
      :code => "REC3424"
    )
  end
  
  it 'should not allow purchase receival entry from non confirmed purchase order entry' do
    @prec_e = PurchaseReceivalEntry.create_object(
      :purchase_receival_id => @prec.id ,
      :purchase_order_entry_id => @poe.id,
      :quantity => 1 
    )
    
    @prec_e.should_not be_valid
  end
  
  context "confirming the po" do
    before(:each) do
      @po.confirm
      @po.reload
      @poe.reload 
    end
    
    it 'should allow purchase receival entry creation with confirmed po' do
      @prec_e = PurchaseReceivalEntry.create_object(
        :purchase_receival_id => @prec.id ,
        :purchase_order_entry_id => @poe.id,
        :quantity => 1 ,
        :supplier_id => @supplier.id 
        
      )
      
      @prec_e.should be_valid 
    end
    
    it 'should not allow creation if quantity > quantity ordered in po entry' do
      @prec_e = PurchaseReceivalEntry.create_object(
        :purchase_receival_id => @prec.id ,
        :purchase_order_entry_id => @poe.id,
        :quantity => @quantity + 1 ,
        :supplier_id => @supplier.id 
        
      )
      
      @prec_e.should_not be_valid 
      @prec_e.errors.size.should_not == 0 
    end
    
    context "created po entry" do
      before(:each) do
        @received_quantity = 2
        @prec_e = PurchaseReceivalEntry.create_object(
          :purchase_receival_id => @prec.id ,
          :purchase_order_entry_id => @poe.id,
          :quantity => @received_quantity ,
          :supplier_id => @supplier.id 

        )
      end
      
      it 'should allow delete' do
        @prec_e.delete_object
        @prec_e.persisted?.should be_false 
      end

      it 'should allow update' do
        @prec_e.update_object(
          :purchase_receival_id => @prec.id ,
          :purchase_order_entry_id => @poe.id,
          :quantity => 1,
          :supplier_id => @supplier.id 

        )
        
        @prec_e.should be_valid
        @prec_e.errors.size.should == 0 
      end
      
      context "confirm preceival" do
        before(:each) do
          @wh_item_1 = WarehouseItem.find_or_create_object(
            :warehouse_id => @wh_1.id ,
            :item_id => @item_1.id 
          )
          @poe.reload 
          @item_1.reload 
          
          @initial_poe_pending_receival = @poe.pending_receival
          @initial_poe_received = @poe.received 
          
          @initial_item_1_ready = @item_1.ready 
          @initial_wh_item_1_ready = @wh_item_1.ready 
          @initial_item_1_pending_receival = @item_1.pending_receival
          @initial_wh_item_1_pending_receival = @wh_item_1.pending_receival 
          
          @initial_item_1_pending_receival = @item_1.pending_receival
          @initial_wh_item_1_pending_receival = @wh_item_1.pending_receival
          @prec.confirm 
          @prec_e.reload 
          @item_1.reload 
          @wh_item_1.reload
          @poe.reload 
          
        end
        
        it 'should update purchase_order_entry.pending receival and received' do
          @po.is_confirmed.should be_true 
          final_poe_pending_receival = @poe.pending_receival
          final_poe_received = @poe.received 
          # puts "quantity_ordered: #{@poe.quantity}"
          # puts "final_poe_pending_receival: #{final_poe_pending_receival}"
          # puts "final_poe_received: #{final_poe_received}"
          
          diff_poe_pending_receival  = final_poe_pending_receival - @initial_poe_pending_receival
          diff_poe_received = final_poe_received - @initial_poe_received
          
          diff_poe_pending_receival.should == -1*@received_quantity 
          diff_poe_received.should == @received_quantity
        end
        
        it 'should update ready item' do
          final_item_1_ready  = @item_1.ready 
          final_wh_item_1_ready = @wh_item_1.ready 
          diff_item_1 = final_item_1_ready - @initial_item_1_ready
          diff_wh_item_1 = final_wh_item_1_ready - @initial_wh_item_1_ready
          
          diff_item_1.should == @received_quantity
          diff_wh_item_1.should == @received_quantity
        end
        
        it 'should update pending receival' do
          final_item_1_pending_receival = @item_1.pending_receival
          final_wh_item_1_pending_receival = @wh_item_1.pending_receival
          
          diff_item_1 = final_item_1_pending_receival - @initial_item_1_pending_receival
          diff_wh_item_1 = final_wh_item_1_pending_receival - @initial_wh_item_1_pending_receival
          
          final_item_1_pending_receival.should == 3 
          @initial_item_1_pending_receival.should == 5 
          
          diff_item_1.should == -1*@received_quantity 
          diff_wh_item_1.should == -1*@received_quantity  
        end
        
        it 'should not allow delete' do
          @prec_e.delete_object
          @prec_e.errors.size.should_not == 0 
          @prec_e.persisted?.should be_true 
        end
        
        it 'should not allow update' do
          @prec_e.update_object(
            :purchase_receival_id => @prec.id ,
            :purchase_order_entry_id => @poe.id,
            :quantity => 2,
            :supplier_id => @supplier.id 
          )
          
          @prec_e.errors.size.should_not ==  0 
        end
        
        context "unconfirm" do
          before(:each) do
            @prec.unconfirm
            @prec_e.reload 
            @item_1.reload 
            @wh_item_1.reload
          end
          
          it 'should not be confirmed' do
            @prec.is_confirmed.should be_false
            @prec_e.is_confirmed.should be_false 
          end
          
          it 'should refresh the pending receival' do
            @item_1.pending_receival.should == @quantity
            @wh_item_1.pending_receival.should == @quantity
            @item_1.ready.should == 0 
            @wh_item_1.ready.should  == 0 
          end
        end
        
      end
    end
    
    
  end
end
