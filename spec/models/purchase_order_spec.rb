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
    
    @supplier = Supplier.create_object(
      :name => "Supplier 1 "
    )
  end
  
  it 'should be allowed to create purchase order' do
    @po = PurchaseOrder.create_object(
      :supplier_id => @supplier.id ,
      :warehouse_id => @wh_1.id ,
      :description => "The description",
      :code => "PO1234"
    )
    @po.errors.messages.each do |msg|
      puts "The message: #{msg}"
    end 
    @po.should be_valid 
  end
  
  it 'should not be allowed to create po with wrong/non existant item' do
    @po = PurchaseOrder.create_object(
      :supplier_id => @supplier.id ,
      :warehouse_id => 0,
      :description => "The description",
      :code => "PO1234"
    )
    
    @po.should_not be_valid
  end
  
  
  context "created po" do
    before(:each) do
      @po = PurchaseOrder.create_object(
        :supplier_id => @supplier.id ,
        :warehouse_id => @wh_1.id ,
        :description => "The description",
        :code => "PO1234"
      )
       
    end
    
    it 'should not be allowed to confirm' do
      @po.confirm
      @po.errors.size.should_not == 0 
    end
    
    it 'should create po' do
      @po.should be_valid 
    end
    
    it 'should create po entry' do
      @quantity = 5 
      @poe = PurchaseOrderEntry.create_object(
        :purchase_order_id => @po.id ,
        :item_id => @item_1.id ,
        :quantity => @quantity
      )
      
      @poe.should be_valid 
    end 
    
    context "created po entry" do
      before(:each) do
        @quantity = 5 
        @poe = PurchaseOrderEntry.create_object(
          :purchase_order_id => @po.id ,
          :item_id => @item_1.id ,
          :quantity => @quantity
        )
      end
      
      it 'should create po entry' do
        @poe.should be_valid 
      end
      
      it 'should not increse teh item#pending_receival' do
        @item_1.reload 
        @item_1.pending_receival.should ==0  
      end
      
      it 'should not allow deletion of purchase order' do
        @po.delete_object
        @po.persisted?.should be_true 
        @po.errors.size.should_not == 0 
      end
      
      context "confirmation of po" do
        before(:each) do
          @initial_item_1_pending_receival = @item_1.pending_receival
          @po.confirm 
          @poe.reload 
          @item_1.reload 
        end
        
        it 'should confirm po' do
          @po.is_confirmed.should be_true 
        end
        
        it 'should confirm the poe' do
          @poe.is_confirmed.should be_true 
        end
        
        it 'should increase the pending receival' do
          @final_item_1_pending_receival = @item_1.pending_receival
          
          diff = @final_item_1_pending_receival - @initial_item_1_pending_receival
          diff.should == @quantity 
        end
        
        
        it 'should not be updatable' do
          @po.update_object(
            :supplier_id => @supplier.id ,
            :warehouse_id => @wh_1.id ,
            :description => "The description 2",
            :code => "PO1234"
          )
          @po.errors.size.should_not == 0 
        end
        
        it 'should not be deletable' do
          @po.delete_object 
          @po.persisted?.should be_true 
          @po.errors.size.should_not == 0 
        end
        
        
        context "unconfirm" do
          before(:each) do
            @po.unconfirm
          end
          
          it 'should unconfirm the po' do
            @po.is_confirmed.should be_false 
          end
          
          it 'should allow update object' do
            @po.update_object(
              :supplier_id => @supplier.id ,
              :warehouse_id => @wh_1.id ,
              :description => "The description 2",
              :code => "PO1234"
            )
            @po.errors.size.should == 0
          end
        end
      end
    end
  end
  
  
  
  
  
end
