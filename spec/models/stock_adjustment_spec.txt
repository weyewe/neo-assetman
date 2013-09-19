require 'spec_helper'

describe StockAdjustment do
  before(:each) do
    @wh_1 = Warehouse.create_object(
      :name => "Warehouse 1",
      :description => "Our main warehouse"
    )
    
    @item_1 = Item.create_object(
      :name => "Hose 5m",
      :code => "HS34"
    )
  end
  
  it 'should create stock adjustment' do
    @adj_quantity = 5 
    @stock_adjustment = StockAdjustment.create_object(
      :item_id => @item_1.id,
      :warehouse_id => @wh_1.id ,
      :actual_quantity => @adj_quantity
    )
    
    @stock_adjustment.should be_valid 
  end
  
  it 'should not create stock adjustment with negative actual quantity' do
    @adj_quantity = -5 
    @stock_adjustment = StockAdjustment.create_object(
      :item_id => @item_1.id,
      :warehouse_id => @wh_1.id ,
      :actual_quantity => @adj_quantity
    )
    
    @stock_adjustment.should_not be_valid
  end
  
  context "create the stock_adjustment: produces warehouse_item if it is not available" do
    before(:each) do
      @adj_quantity = 5 
      @stock_adjustment = StockAdjustment.create_object(
        :item_id => @item_1.id,
        :warehouse_id => @wh_1.id ,
        :actual_quantity => @adj_quantity
      )
      
      @stock_adjustment.reload
    end
    
    it 'should assign warehouse_item' do
      @stock_adjustment.warehouse_item_id.should_not be_nil 
      WarehouseItem.count.should == 1 
    end
    
    
    it 'should produce warehouse item' do
      WarehouseItem.where(:warehouse_id => @wh_1.id , :item_id => @item_1.id ).count.should == 1 
      
      WarehouseItem.find_or_create_object(:warehouse_id => @wh_1.id, :item_id => @item_1.id)
      
      WarehouseItem.count.should == 1 
    end
    
    context "update before confirm" do
      before(:each) do
        @new_adj_quantity = @adj_quantity + 9
        @stock_adjustment.update_object(
          :item_id => @item_1.id,
          :warehouse_id => @wh_1.id ,
          :actual_quantity => @new_adj_quantity
        )
      end
      
      it 'should update the actual quantity' do
        @stock_adjustment.actual_quantity.should == @new_adj_quantity
      end
    end
    
    context "delete before confirm" do
      before(:each) do
        @new_adj_quantity = @adj_quantity + 9
        @stock_adjustment.delete_object
      end
      
      it 'should delete the object' do
        @stock_adjustment.persisted?.should be_false 
      end
    end
    
    context "confirm" do
      before(:each) do
        @wh_item_1 = WarehouseItem.where(
          :warehouse_id => @wh_1.id , 
          :item_id => @item_1.id 
        ).first 
        
        @initial_item_ready = @item_1.ready 
        @initial_warehouse_item_ready = @wh_item_1.ready 
        @stock_adjustment.confirm 
        
        @item_1.reload 
        @wh_item_1.reload 
        @stock_adjustment.reload 
      end
      
      it 'should confirm' do
        @stock_adjustment.is_confirmed.should be_true 
      end
      
      it 'should update ready quantity in item and warehouse_item' do
        final_item_ready = @item_1.ready 
        final_wh_item_ready = @wh_item_1.ready 
        
        diff_item = final_item_ready - @initial_item_ready
        diff_wh_item = final_wh_item_ready - @initial_warehouse_item_ready
        
        diff_item.should == @adj_quantity
        diff_wh_item.should == @adj_quantity
      end
      
      it "it should update the warehouse item" do
        @wh_item_1.ready.should == @adj_quantity
      end
      
      it 'should create one stock mutation' do
        StockMutation.count.should == 1 
        @sm = StockMutation.first 
        
        @sm.case.should ==  STOCK_MUTATION_CASE[:ready]
        @sm.quantity.should == @adj_quantity
        @sm.stock_mutation_source_id.should == @stock_adjustment.id 
        @sm.stock_mutation_source_type.should == @stock_adjustment.class.to_s
        
        @wh_item_1.stock_mutations.count.should == 1 
        @item_1.stock_mutations.count.should == 1 
        @wh_1.stock_mutations.count.should == 1 
      end
      
      context "update post confirm" do
        before(:each) do
          @new_adj_quantity = @adj_quantity + 9
          @stock_adjustment.update_object(
            :item_id => @item_1.id,
            :warehouse_id => @wh_1.id ,
            :actual_quantity => @new_adj_quantity
          )
        end
        
        it 'should not be valid' do
          @stock_adjustment.errors.size.should_not == 0 
        end
      end
      
      context "delete post confirm" do
        before(:each) do
          @new_adj_quantity = @adj_quantity + 9
          @stock_adjustment.delete_object 
        end
        
        it 'should not be valid' do
          @stock_adjustment.errors.size.should_not == 0 
        end
      end
      
      context "unconfirm the stock adjustment" do
        before(:each) do 
          @stock_adjustment.unconfirm
          @item_1.reload 
          @wh_item_1.reload
          @wh_1.reload 
          @stock_adjustment.reload 
        end
        
        it 'should produce no error' do
          @stock_adjustment.errors.messages.each do |msg|
            puts "3321 the error : #{msg}"
          end
          @stock_adjustment.errors.size.should == 0 
        end
        
        it 'should unconfirm' do
          @stock_adjustment.is_confirmed.should be_false 
        end
        
        it 'should be updatable' do
          @new_adj_quantity = @adj_quantity + 9
          @stock_adjustment.update_object(
            :item_id => @item_1.id,
            :warehouse_id => @wh_1.id ,
            :actual_quantity => @new_adj_quantity
          )
          
          @stock_adjustment.errors.size.should == 0 
          @stock_adjustment.actual_quantity.should == @new_adj_quantity
        end
        
        it 'should destroy the stock mutations' do
          @stock_adjustment.stock_mutation.should be_nil 
          @item_1.stock_mutations.count.should == 0 
          @wh_item_1.stock_mutations.count.should == 0 
          @wh_1.stock_mutations.count.should == 0 
        end
        
        it 'shoud reverse the ready item quantity' do
          @item_1.ready.should == 0  
          @wh_item_1.ready.should ==0  
        end
      end
      
      
    end
  end
end
