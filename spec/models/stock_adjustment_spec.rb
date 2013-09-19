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
    
    @supplier = Supplier.create_object(
      :name => "Supplier 1 "
    )
    
    @adjusted_at = DateTime.new(2012,10,5,0,0,0)
  end
  
  it 'should be allowed to create purchase order' do
    @sa = StockAdjustment.create_object(
      :adjusted_at  => @adjusted_at,  
      :warehouse_id => @wh_1.id ,  
      :description  => "The adjustment description",  
      :code         => "ADJ234" 
    )
    
    
    @sa.should be_valid 
  end
  
  it 'should not be allowed to create po with wrong/non existant item' do
    @sa = StockAdjustment.create_object(
      :adjusted_at  => @adjusted_at,  
      :warehouse_id => 0 ,  
      :description  => "The adjustment description",  
      :code         => "ADJ234"
    )
    
    @sa.should_not be_valid
  end
  
  
  context "created sa" do
    before(:each) do
      @sa = StockAdjustment.create_object(
        :adjusted_at  => @adjusted_at,  
        :warehouse_id => @wh_1.id ,  
        :description  => "The adjustment description",  
        :code         => "ADJ234"
      )
       
    end
    
    # it 'should not be allowed to confirm' do
    #   @sa.confirm
    #   @sa.errors.size.should_not == 0 
    # end
    # 
    # it 'should create sa' do
    #   @sa.should be_valid 
    # end
    
    it 'should create sa entry' do
      @quantity = 5 
      
      @sa.should be_valid
      @item_1.should be_valid
      
      @sae = StockAdjustmentEntry.create_object(
        :stock_adjustment_id => @sa.id ,
        :item_id => @item_1.id ,
        :actual_quantity => @quantity
      )
      
      @sae.errors.messages.each {|x| puts "msg: #{x}"}
      
      @sae.should be_valid 
    end 
    
    
    
    context "created sa entry" do
      before(:each) do
        @quantity = 5 
        @sae = StockAdjustmentEntry.create_object(
          :stock_adjustment_id => @sa.id ,
          :item_id => @item_1.id ,
          :actual_quantity => @quantity
        )
      end
      
      it 'should create sa entry' do
        @sae.should be_valid 
      end
      
      it 'should not increse teh item#ready' do
        @item_1.reload 
        @item_1.ready.should ==0  
      end
      
      it 'should not allow deletion of purchase order' do
        @sa.delete_object
        @sa.persisted?.should be_true 
        @sa.errors.size.should_not == 0 
      end
      
      context "confirmation of sa" do
        before(:each) do
          @wh_item_1 = WarehouseItem.find_or_create_object(:warehouse_id => @wh_1.id, :item_id => @item_1.id )
          @item_1.reload 
          @initial_wh_item_1_ready = @wh_item_1.ready
          @initial_item_1_ready = @item_1.ready
          @sa.confirm 
          @sae.reload 
          @item_1.reload 
          @wh_item_1.reload 
        end
        
        
        
        it 'should confirm sa' do
          @sa.is_confirmed.should be_true 
        end
        
        it 'should confirm the sae' do
          @sae.is_confirmed.should be_true 
        end
        
        it 'should increase the ready: in both item and warehouse item' do
          @final_item_1_ready = @item_1.ready
          @final_wh_item_1_ready = @wh_item_1.ready 
          diff_item_1 = @final_item_1_ready - @initial_item_1_ready
          diff_item_1.should == @quantity 
          
          diff_wh_item_1 = @final_wh_item_1_ready - @initial_wh_item_1_ready
          diff_wh_item_1.should == @quantity
        end
        
        
        it 'should not be updatable' do
          @sa.update_object(
            :adjusted_at  => @adjusted_at,  
            :warehouse_id => @wh_1.id ,  
            :description  => "The adjustment description",  
            :code         => "ADJ234333"
          )
          @sa.errors.size.should_not == 0 
        end
        
        it 'should not be deletable' do
          @sa.delete_object 
          @sa.persisted?.should be_true 
          @sa.errors.size.should_not == 0 
        end
        
        
        
        context "unconfirm" do
          before(:each) do
            # this is important. or else, will call the old data (thanks to rails DB caching)
            @wh_item_1.reload 
            @item_1.reload 
            @initial_wh_item_1_ready = @wh_item_1.ready
            @initial_item_1_ready = @item_1.ready
            
            @sa.reload
            @sa.unconfirm
            
            @sae.reload 
            @item_1.reload 
            @wh_item_1.reload
          end
          
          it 'should reverse the ready quantity' do
            @final_item_1_ready = @item_1.ready
            @final_wh_item_1_ready = @wh_item_1.ready 
            diff_item_1 = @final_item_1_ready - @initial_item_1_ready
            diff_item_1.should == -1*@quantity 

            diff_wh_item_1 = @final_wh_item_1_ready - @initial_wh_item_1_ready
            diff_wh_item_1.should == -1* @quantity
          end
          
          
          it 'should unconfirm the po' do 
            @sa.is_confirmed.should be_false 
          end
          
          it 'should allow update object' do
            @sa.update_object(
              :adjusted_at  => @adjusted_at,  
              :warehouse_id => @wh_1.id ,  
              :description  => "The adjustment description",  
              :code         => "ADJ23324"
            )
            @sa.errors.size.should == 0
          end
        end
      end
    end
      
      
  
  
  end
  
  
  
  
  
end
