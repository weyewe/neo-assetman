require 'spec_helper'

describe WarehouseMutationEntry do
  before(:each) do
    @wh_1 = Warehouse.create_object(
      :name => "Warehouse 1",
      :description => "Our main warehouse"
    )
    
    @wh_2 = Warehouse.create_object(
      :name => "Warehouse 2",
      :description => "Mobile Warehouse #1"
    )
    
    @item_1 = Item.create_object(
      :name => "Hose 5m",
      :code => "HS34"
    )
    
    @item_2 = Item.create_object(
      :name => "haha Hose 5m",
      :code => "@33HS34"
    )
    
    @item_3 = Item.create_object(
      :name => "33 haha Hose 5m",
      :code => "aa@33HS34"
    )
    
    @supplier = Supplier.create_object(
      :name => "Supplier 1 "
    )
    
    @adjusted_at = DateTime.new(2012,5,5,0,0,0)
    @mutated_at = DateTime.new(2012,10,5,0,0,0)
    
    
    @quantity = 5 
    @sa = StockAdjustment.create_object(
      :adjusted_at  => @adjusted_at,  
      :warehouse_id => @wh_1.id ,  
      :description  => "The adjustment description",  
      :code         => "ADJ234" 
    )
    
    @sae = StockAdjustmentEntry.create_object(
      :stock_adjustment_id => @sa.id ,
      :item_id => @item_1.id ,
      :actual_quantity => @quantity
    )
    @sae_2 = StockAdjustmentEntry.create_object(
      :stock_adjustment_id => @sa.id ,
      :item_id => @item_2.id ,
      :actual_quantity => @quantity
    )
    
    @sa.reload
    @sa.confirm 
    @item_1.reload 
    @wh_item_1 = WarehouseItem.find_or_create_object(
      :warehouse_id => @wh_1.id , 
      :item_id => @item_1.id 
    )
    @wh_item_2 = WarehouseItem.find_or_create_object(
      :warehouse_id => @wh_1.id , 
      :item_id => @item_2.id 
    )
    
    @wm = WarehouseMutation.create_object(
      :mutated_at          =>  @mutated_at  ,            
      :source_warehouse_id => @wh_1.id    ,              
      :target_warehouse_id =>   @wh_2.id ,               
      :description         =>   "awesome description" ,  
      :code                =>"WM234234"                  
    )
    
    @item_1.reload
    @item_2.reload
    @wh_item_1.reload
    @wh_item_2.reload 
  end
    
  it 'should allow creation of @wme' do
    @wme_1 = WarehouseMutationEntry.create_object(
    :item_id               => @item_1.id,  
    :warehouse_mutation_id => @wm.id ,   
    :quantity              =>  @item_1.ready - 1  
    )

    @wme_1.should be_valid 
  end
  
  it 'should NOT allow creation of @wme with 0 quantity' do
    @wme_1 = WarehouseMutationEntry.create_object(
    :item_id               => @item_1.id,  
    :warehouse_mutation_id => @wm.id ,   
    :quantity              =>    0
    )

    @wme_1.should_not be_valid 
    
    @wme_1 = WarehouseMutationEntry.create_object(
    :item_id               => @item_1.id,  
    :warehouse_mutation_id => @wm.id ,   
    :quantity              =>    @item_1.ready + 1 
    )

    @wme_1.should_not be_valid
  end
  
  it 'should not allow creation if quantity > ready quantity' do
    @wme_1 = WarehouseMutationEntry.create_object(
    :item_id               => @item_3.id,  
    :warehouse_mutation_id => @wm.id ,   
    :quantity              =>     1
    )

    @wme_1.should_not be_valid
    
    @wh_item = WarehouseItem.where(
      :item_id => @item_3.id,
      :warehouse_id => @wh_1.id 
    ).first 
    @wh_item.should be_valid 
  end
  
  
  
  it 'should not allow wme with equal item_id' do
    @wme_1 = WarehouseMutationEntry.create_object(
    :item_id               => @item_1.id,  
    :warehouse_mutation_id => @wm.id ,   
    :quantity              =>  @item_1.ready - 1  
    )

    @wme_1.should be_valid
    
    @wme_2 = WarehouseMutationEntry.create_object(
    :item_id               => @item_1.id,  
    :warehouse_mutation_id => @wm.id ,   
    :quantity              =>  1 
    )

    @wme_2.should_not be_valid
  end
  
  
  
  
  
  context "creation of wme_1" do
    before(:each) do
      @mutated_quantity = 2
      @wme_1 = WarehouseMutationEntry.create_object(
        :item_id               => @item_1.id,  
        :warehouse_mutation_id => @wm.id ,   
        :quantity              =>  @mutated_quantity
      )

    end
    
    it 'should create wme' do
      @wme_1.should be_valid 
    end
    
    it 'should allow_update' do
      @wme_1.update_object(
        :item_id               => @item_2.id,  
        :warehouse_mutation_id => @wm.id ,   
        :quantity              =>  @mutated_quantity
      )
      
      @wme_1.errors.size.should == 0 
      @wme_1.should be_valid 
    end
    
    it 'should allow deletion' do
      @wme_1.delete_object
      @wme_1.persisted?.should be_false 
    end
    
    it 'should not allow 2 entries with similar item_id' do
      @wme_2 = WarehouseMutationEntry.create_object(
        :item_id               => @item_1.id,  
        :warehouse_mutation_id => @wm.id ,   
        :quantity              =>  @mutated_quantity
      )
      
      @wme_2.should_not be_valid 
    end
    
    context "creating wme_2" do
      before(:each) do
        @wme_2 = WarehouseMutationEntry.create_object(
          :item_id               => @item_2.id,  
          :warehouse_mutation_id => @wm.id ,   
          :quantity              =>  @mutated_quantity
        )
      end
      
      it 'should create wme 2' do
        @wme_2.should be_valid 
      end
      
      it 'should not allow update wme_2 to use item_1' do
        @wme_2.update_object(
          :item_id               => @item_1.id,  
          :warehouse_mutation_id => @wm.id ,   
          :quantity              =>  @mutated_quantity
        )
        
        @wme_2.errors.size.should_not ==0  
      end
    end
    
    context "confirm the wm" do
      before(:each) do
        @wm.reload 
        @wh_1_item_1 = WarehouseItem.find_or_create_object(
          :warehouse_id => @wh_1.id ,
          :item_id => @item_1.id 
        )
        @wh_2_item_1 = WarehouseItem.find_or_create_object(
          :warehouse_id => @wh_2.id , # wh_2 is the target mutation 
          :item_id => @item_1.id 
        )
        @item_1.reload 
        @initial_item_1_ready = @item_1.ready 
        @initial_wh_1_item_1_ready = @wh_1_item_1.ready 
        @initial_wh_2_item_1_ready = @wh_2_item_1.ready 
        
        @wm.confirm 
        @wme_1.reload 
        @item_1.reload 
        @wh_1_item_1.reload 
        @wh_2_item_1.reload 
        
        @final_item_1_ready = @item_1.ready 
        @final_wh_1_item_1_ready = @wh_1_item_1.ready 
        @final_wh_2_item_1_ready = @wh_2_item_1.ready
        
      end
      
      it 'should produce 2 stocks mutation' do
        @wme_1.stock_mutations.count.should == 2 
        @deduction_sm = @wme_1.stock_mutations.where(:warehouse_id => @wh_1.id ).first 
        @addition_sm = @wme_1.stock_mutations.where(:warehouse_id => @wh_2.id ).first 
        
        @deduction_sm.quantity.should == -1*@mutated_quantity
        @addition_sm.quantity.should == @mutated_quantity
        
        @addition_sm.case.should == STOCK_MUTATION_CASE[:ready]
      end
      
      it 'should not change the item_1 ready, but change the wh_1_item_1 and wh_2_item_1' do
         diff_item_1_ready      =  @final_item_1_ready       - @initial_item_1_ready     
         diff_wh_1_item_1_ready =  @final_wh_1_item_1_ready  - @initial_wh_1_item_1_ready      
         diff_wh_2_item_1_ready =  @final_wh_2_item_1_ready  - @initial_wh_2_item_1_ready   
         
         diff_item_1_ready      .should == 0 
         diff_wh_1_item_1_ready .should == -1*@mutated_quantity 
         diff_wh_2_item_1_ready .should == @mutated_quantity 
      end
      
      it 'should not be deletable' do
        @wme_1.delete_object
        @wme_1.errors.size.should_not == 0 
        @wme_1.persisted?.should be_true 
      end
      
      it 'should not be updatable' do
        @wme_1.update_object(
        :item_id               => @item_1.id,  
        :warehouse_mutation_id => @wm.id ,   
        :quantity              =>  @mutated_quantity -1 
        )
        
        @wme_1.errors.size.should_not == 0 
      end
      
      context "unconfirm" do
        before(:each) do
          @item_1.reload 
          @wh_1_item_1.reload 
          @wh_2_item_1.reload 
          @wm.reload 
          @wme_1.reload 
          
          @initial_item_1_ready = @item_1.ready 
          @initial_wh_1_item_1_ready = @wh_1_item_1.ready 
          @initial_wh_2_item_1_ready = @wh_2_item_1.ready
          
          @wm.unconfirm
          
          @item_1.reload 
          @wh_1_item_1.reload 
          @wh_2_item_1.reload 
          @wm.reload 
          @wme_1.reload
          
          @final_item_1_ready = @item_1.ready 
          @final_wh_1_item_1_ready = @wh_1_item_1.ready 
          @final_wh_2_item_1_ready = @wh_2_item_1.ready
        end
        
        it 'should produce 0 stocks mutation' do
          @wme_1.stock_mutations.count.should == 0  
        end
        
        
        it 'should reverse the mutation' do
          diff_item_1_ready      =  @final_item_1_ready       - @initial_item_1_ready     
          diff_wh_1_item_1_ready =  @final_wh_1_item_1_ready  - @initial_wh_1_item_1_ready      
          diff_wh_2_item_1_ready =  @final_wh_2_item_1_ready  - @initial_wh_2_item_1_ready   

          diff_item_1_ready      .should == 0 
          diff_wh_1_item_1_ready .should == -1*-1*@mutated_quantity 
          diff_wh_2_item_1_ready .should == -1*@mutated_quantity
        end
        
        it 'should  be deletable' do
          @wme_1.delete_object
          @wme_1.persisted?.should be_false
        end

        it 'should  be updatable' do
          @wme_1.update_object(
          :item_id               => @item_1.id,  
          :warehouse_mutation_id => @wm.id ,   
          :quantity              =>  @mutated_quantity -1 
          )

          @wme_1.errors.size.should == 0 
        end
      end
    end
    
  end
end
