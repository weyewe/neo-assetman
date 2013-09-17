require 'spec_helper'

describe WarehouseItemMutation do
  before(:each) do
    @wh_1 = Warehouse.create_object(
      :name => "Warehouse 1",
      :description => "Our main warehouse"
    )
    
    @wh_2 = Warehouse.create_object(
      :name => "Warehouse 2",
      :description => "our secondary warehouse"
    )
    
    @item_1 = Item.create_object(
      :name => "Hose 5m",
      :code => "HS34"
    )
    
    @item_2 = Item.create_object(
      :name => "Spatula 5m",
      :code => "HS3425"
    )
    
    @adj_quantity = 5 
    @stock_adjustment = StockAdjustment.create_object(
      :item_id => @item_1.id,
      :warehouse_id => @wh_1.id ,
      :actual_quantity => @adj_quantity
    )
    @stock_adjustment.confirm 
    @item_1.reload 
  end
  
  
  it 'should create valid stock adjustment' do
    @stock_adjustment.should be_valid
    @stock_adjustment.errors.size.should == 0 
  end
  
  it 'should create stock mutation' do
    StockMutation.count.should == 1 
  end
  
  it 'should set produce warehouse_item 1' do
    WarehouseItem.where(:warehouse_id => @wh_1.id, :item_id => @item_1.id ).count.should  == 1 
  end
  
  it 'should create ready item' do
    @item_1.ready.should == @adj_quantity
    WarehouseItem.where(:warehouse_id => @wh_1.id, :item_id => @item_1.id ).first.ready.should == @adj_quantity
  end
  
  it 'should create warehouse item mutation' do
    @quantity = @adj_quantity - 1 
    whi_mutation = WarehouseItemMutation.create_object(
      :source_warehouse_id => @wh_1.id,
      :target_warehouse_id => @wh_2.id,
      :item_id => @item_1.id ,
      :quantity => @quantity
    )
    
    whi_mutation.should be_valid 
  end
  
  it 'should not create whi if source == target' do
    @quantity = @adj_quantity - 1 
    whi_mutation = WarehouseItemMutation.create_object(
      :source_warehouse_id => @wh_1.id,
      :target_warehouse_id => @wh_1.id,
      :item_id => @item_1.id ,
      :quantity => @quantity
    )
    
    whi_mutation.should_not be_valid 
  end
  
  it 'should not create whi if  quantity <= 0 ' do
    @quantity = @adj_quantity - 1 
    whi_mutation = WarehouseItemMutation.create_object(
      :source_warehouse_id => @wh_1.id,
      :target_warehouse_id => @wh_2.id,
      :item_id => @item_1.id ,
      :quantity => 0
    )
    
    whi_mutation.should_not be_valid 
    
    whi_mutation = WarehouseItemMutation.create_object(
      :source_warehouse_id => @wh_1.id,
      :target_warehouse_id => @wh_2.id,
      :item_id => @item_1.id ,
      :quantity => -1
    )
    
    whi_mutation.should_not be_valid
  end
  
  it 'should not create whi if quantity > ready quantity ' do
    @quantity = @adj_quantity + 1 
    whi_mutation = WarehouseItemMutation.create_object(
      :source_warehouse_id => @wh_1.id,
      :target_warehouse_id => @wh_2.id,
      :item_id => @item_1.id ,
      :quantity => @quantity
    )
    
    whi_mutation.should_not be_valid 
  end
  
  it 'should not create whi if there is no such item in the source warehouse' do
    @quantity = @adj_quantity -1 
    whi_mutation = WarehouseItemMutation.create_object(
      :source_warehouse_id => @wh_1.id,
      :target_warehouse_id => @wh_2.id,
      :item_id => @item_2.id ,
      :quantity => @quantity
    )
    
    whi_mutation.should_not be_valid
  end
  
  context "creating warehouse mutation" do
    before(:each) do
      @quantity = @adj_quantity - 1 
      @whi_mutation = WarehouseItemMutation.create_object(
        :source_warehouse_id => @wh_1.id,
        :target_warehouse_id => @wh_2.id,
        :item_id => @item_1.id ,
        :quantity => @quantity
      ) 
    end
    
    it 'should create valid warehouse mutation' do
      @whi_mutation.should be_valid 
    end
    
    it 'should be updatable' do
      @whi_mutation.update_object(
        :source_warehouse_id => @wh_1.id,
        :target_warehouse_id => @wh_2.id,
        :item_id => @item_1.id ,
        :quantity => @quantity -1 
      )
      
      @whi_mutation.should be_valid
      @whi_mutation.quantity.should == @quantity -1 
    end
    
    it 'should be deletable' do
      @whi_mutation.delete_object
      @whi_mutation.persisted?.should be_false 
    end
    
    context "confirming warehouse_item_mutation" do
      before(:each) do
        @item_1.reload
        @whi_1 = WarehouseItem.find_or_create_object(:warehouse_id => @wh_1.id, :item_id => @item_1.id )
        @whi_2 = WarehouseItem.where(:warehouse_id => @wh_2.id, :item_id => @item_1.id ).first
        @initial_item_ready = @item_1.ready 
        @initial_whi_1_ready = @whi_1.ready 
        @whi_mutation.confirm
        @whi_mutation.reload
        @item_1.reload
        @whi_1.reload 
      end
      
      it 'should not have whi_2 in the beginning' do 
        @whi_2.should be_nil 
      end
      
      it 'should be confirmed' do
        @whi_mutation.is_confirmed.should be_true 
      end

      it 'should create 2 stock_mutations' do
        @whi_mutation.stock_mutations.count.should == 2 
      end
      
      it 'should create 1 stock mutation with negative quantity and 1 with positive quantity' do
        negative_sm = @whi_mutation.stock_mutations.where{ quantity.lt 0}.first 
        positive_sm = @whi_mutation.stock_mutations.where{quantity.gt 0 }.first 
        
        negative_sm.case.should == STOCK_MUTATION_CASE[:ready]
        positive_sm.case.should == STOCK_MUTATION_CASE[:ready]
        
        negative_sm.quantity.should == ( @whi_mutation.quantity * -1 )
        positive_sm.quantity.should == ( @whi_mutation.quantity   )
        
        negative_sm.warehouse_id.should == @wh_1.id
        positive_sm.warehouse_id.should == @wh_2.id 
        
      end
      
      it 'should update the warehouse item' do
        @final_whi_1_ready = @whi_1.ready 
        diff = @final_whi_1_ready - @initial_whi_1_ready 
        diff.should == -1*@quantity
      end
      
      it 'should create warehouse item 2 ' do
        @whi_2 = WarehouseItem.find_or_create_object(:warehouse_id => @wh_2.id, :item_id => @item_1.id )
        @whi_2.ready.should == @quantity 
      end
      
      it 'should not update the item quantity' do
        @final_item_ready = @item_1.ready 
        diff = @final_item_ready - @initial_item_ready 
        diff.should == 0 
      end
      
      
      it 'should not be allowed to update' do
        @whi_mutation.update_object(
          :source_warehouse_id => @wh_1.id,
          :target_warehouse_id => @wh_2.id,
          :item_id => @item_1.id ,
          :quantity => @quantity - 2
        )
        
        @whi_mutation.errors.size.should_not == 0 
      end
      
      it 'should not be allowed to delete ' do
        @whi_mutation.delete_object
        
        @whi_mutation.errors.size.should_not == 0
      end
      
      context "unconfirm teh mutation" do
        before(:each) do
          @whi_mutation.unconfirm
          @whi_2 = WarehouseItem.find_or_create_object(:warehouse_id => @wh_2.id, :item_id => @item_1.id )
          @whi_1.reload
          @item_1.reload 
        end
        
        it 'should unconfirm' do
          @whi_mutation.is_confirmed.should be_false 
        end
        
        it 'should destroy all stock_mutations' do
          @whi_mutation.stock_mutations.count.should == 0 
        end
        
        it 'should refresh the quantity' do
          @item_1.ready.should == @adj_quantity
          @whi_1.ready.should == @adj_quantity
          @whi_2.ready.should == 0 
        end

        it 'should be updatable' do
          @whi_mutation.update_object(
            :source_warehouse_id => @wh_1.id,
            :target_warehouse_id => @wh_2.id,
            :item_id => @item_1.id ,
            :quantity => @quantity - 2
          )
          
          @whi_mutation.errors.size.should == 0 
        end
        it 'should not be allowed to delete ' do
          @whi_mutation.delete_object

          @whi_mutation.persisted?.should be_false 
        end
        
      end
      
      
      
    end
    
    
  end
  
end
