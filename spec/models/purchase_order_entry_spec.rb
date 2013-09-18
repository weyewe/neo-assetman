require 'spec_helper'

describe PurchaseOrderEntry do
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
    
    
    @po = PurchaseOrder.create_object(
      :supplier_id => @supplier.id ,
      :warehouse_id => @wh_1.id ,
      :description => "The description",
      :code => "PO1234",
      :purchased_at => @purchased_at
    )
  end

  it 'should not be allowed to confirm' do
    @po.confirm
    @po.errors.size.should_not == 0 
  end
  
  it 'should be allowed to create purchase order entry' do
    poe = PurchaseOrderEntry.create_object(
      :purchase_order_id => @po.id ,
      :item_id => @item_1.id ,
      :quantity => 5
    )
    
    poe.should be_valid 
  end
  
  context "poe created" do
    before(:each) do
      @quantity = 5 
      @poe = PurchaseOrderEntry.create_object(
        :purchase_order_id => @po.id ,
        :item_id => @item_1.id ,
        :quantity => @quantity
      )
    end
    
    it 'should create poe' do
      @poe.should be_valid 
    end
    
    it 'should be updatable' do
      @poe.update_object(
        :purchase_order_id => @po.id ,
        :item_id => @item_1.id ,
        :quantity => @quantity + 1 
      )
      
      @poe.errors.size.should == 0 
    end
    
    it 'should be deletable' do
      @poe.delete_object 
      @poe.persisted?.should be_false 
    end
    
    context "po is confirmed" do
      before(:each) do 
        @item_1.reload 
        @wh_item_1 = WarehouseItem.find_or_create_object(
          :warehouse_id => @wh_1.id , 
          :item_id => @item_1.id 
        )
        @initial_item_1_pending_receival = @item_1.pending_receival
        @initial_wh_item_1_pending_receival = @wh_item_1.pending_receival
        
        
        @po.confirm 
        @poe.reload 
        @item_1.reload 
        @wh_item_1.reload 
        
        
        
      end
      
      it 'should create warehouse item 1 ' do
        @wh_item_1.should be_valid 
      end
      
      it 'should confirm po and purchase order entry' do
        @po.is_confirmed.should be_true 
        @poe.is_confirmed.should be_true 
      end
      
      it 'should increase the item + warehouse item pending receivable' do
        @final_item_1_pending_receival = @item_1.pending_receival
        @final_wh_item_1_pending_receival = @wh_item_1.pending_receival
        diff_item_1 = @final_item_1_pending_receival -  @initial_item_1_pending_receival
        diff_wh_item_1 = @final_wh_item_1_pending_receival - @initial_wh_item_1_pending_receival
        
        diff_item_1.should == @quantity
        diff_wh_item_1.should == @quantity
      end
      
      it 'should not be updatable' do
        @poe.update_object(
          :purchase_order_id => @po.id ,
          :item_id => @item_1.id ,
          :quantity => @quantity + 1
        )
        
        @poe.errors.size.should_not == 0 
      end
      
      it 'should not be deletable' do
        @poe.delete_object
        @poe.persisted?.should be_true 
        @poe.errors.size.should_not == 0 
      end
      
      it 'should be unconfirmable' do
        @poe.can_be_unconfirmed?.should be_true 
      end
      
      context "unconfirm" do
        before(:each) do
          # puts "=========> Gonna unconfirm po"
          @po.reload
          @po.unconfirm
          @poe.reload
          
          @item_1.reload 
          @wh_item_1.reload
        end
        
        it 'should unconfirm po and poe' do
          @po.is_confirmed.should be_false 
          @poe.is_confirmed.should be_false 
        end
        
        it 'should cancel the pending receival' do
          @item_1.pending_receival.should == 0 
          @wh_item_1.pending_receival.should == 0
        end
        
        it 'should be updatable' do
          @poe.update_object(
            :purchase_order_id => @po.id ,
            :item_id => @item_1.id ,
            :quantity => @quantity + 1
          )

          @poe.errors.size.should == 0 
        end
        
        it 'should be deletable' do
          @poe.delete_object 
          @poe.persisted?.should be_false 
        end
      end
    end
    
    
  end
  
end
