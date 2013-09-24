require 'spec_helper'

describe JobOrderEntry do
  before(:each) do
    @wh_1 = Warehouse.create_object(
      :name => "Warehouse 1",
      :description => "Our main warehouse"
    )
    
    @wh_2 = Warehouse.create_object(
      :name => "Warehouse 2",
      :description => "Mobile Warehouse #1"
    )
    
    @employee = Employee.create_object(
      :name => "Karyawan 1"
    )
    
    @name_1=  "Awesome1"
    @machine_1 = Machine.create_object(
      :name => @name_1 
    )
    @name_2 =  "Awesome2"
    @machine_2 = Machine.create_object(
      :name => @name_2 
    )
    @component_name_1 = "Component1"
    @component_name_2 = "Component2"
    
    @component_1 = Component.create_object(
      :machine_id => @machine_1.id,
      :name => @component_name_1 
    )
    
    @component_2 = Component.create_object(
      :machine_id => @machine_1.id,
      :name => @component_name_2 
    )
    
    @component_2_1_name = "COMP21"
    @component_2_2_name = "COMP22"
    @component_2_3_name = "COMP23"
    
    @component_2_1 = Component.create_object(
      :machine_id => @machine_2.id,
      :name => @component_2_1_name 
    )
    @component_2_1 = Component.create_object(
      :machine_id => @machine_2.id,
      :name => @component_2_2_name 
    )
    @component_2_1 = Component.create_object(
      :machine_id => @machine_2.id,
      :name => @component_2_3_name 
    )
    
    
    
    
    
    @component_1_item_1_name = "Item1"
    @component_2_item_1_name = "Item2"
    @component_1_item_1_code = "faewf"
    @component_2_item_1_code = "HS234"
    
    @component_1_item_1 = Item.create_object(
      :name =>  @component_1_item_1_name,
      :code => @component_1_item_1_code
    )
    
    @component_2_item_1 = Item.create_object(
      :name => @component_2_item_1_name ,
      :code => @component_2_item_1_code
    )
    
    @compatibility_1_item_1 = Compatibility.create_object(
      :item_id => @component_1_item_1.id,
      :component_id => @component_1.id 
    )
    
    @compatibility_2_item_1 = Compatibility.create_object(
      :item_id => @component_2_item_1.id,
      :component_id => @component_2.id 
    )
    
    @item_3 = Item.create_object(
      :name =>  "Item 3 name",
      :code => 'xafaw3'
    )
    
   
    @customer = Customer.create_object(
      :name => "Customer1"
    )
    
    
    @asset_1_code = "hh234"
    @asset = Asset.create_object(
      :customer_id => @customer.id, 
      :machine_id => @machine_1.id ,
      :code => @asset_1_code
    )
    
    @asset.reload 
    @order_date = DateTime.new(2013,12,11,0 ,0 ,0)
    @adjusted_at = DateTime.new(2012,10,5,0,0,0)
    
    @job_order = JobOrder.create_object(
      :customer_id  => @customer.id,
      :warehouse_id => @wh_1.id,
      :asset_id     => @asset.id,
      :employee_id  => @employee.id,
      :code         => 'JO.3321',
      :description  => "Butuh perbaikan. tidak dingin.",
      :order_date   => @order_date,
      :case         => JOB_ORDER_CASE[:emergency]
    )
    @job_order.reload 
  end
  
  it 'should create job order' do
    @job_order.should be_valid
    @job_order.confirm
    @job_order.is_confirmed.should be_false 
    @job_order.errors.size.should_not == 0 
  end
  
  context "update post inspection" do
    before(:each) do
      @joe_1 = @job_order.job_order_entries.where(:component_id => @component_1.id).first
      @joe_2 = @job_order.job_order_entries.where(:component_id => @component_2.id).first
    end
    
    it 'should give @joe_1 and @joe_2' do
      @joe_1.should be_valid
      @joe_2.should be_valid 
    end
    
    it 'should be able to update job inspection result' do
      @joe_1.update_inspection_result(
          :result_case =>   JOB_ORDER_ENTRY_RESULT_CASE[:ok]  , 
          :item_id     =>  nil    , 
          :is_replaced =>  false   , 
          :description =>   "Awesome"
      )
      
      @joe_1.errors.size.should ==  0
    end
    
    it 'should not update job inspection if the result case is invalid' do
      @joe_1.update_inspection_result(
          :result_case =>    9 , 
          :item_id     =>  nil    , 
          :is_replaced =>  false   , 
          :description =>   "Awesome"
      )
      
      @joe_1.errors.size.should_not ==  0
    end
    
    it 'should not update job inspection if the result case is ok, but requires item replacement' do
      @joe_1.update_inspection_result(
          :result_case =>    JOB_ORDER_ENTRY_RESULT_CASE[:ok] , 
          :item_id     =>  @component_1_item_1.id   , 
          :is_replaced =>  true   , 
          :description =>   "Awesome"
      )
      
      @joe_1.errors.size.should_not ==  0
    end
    
    it 'should not contain item_id if is_replaced is false' do
      @joe_1.update_inspection_result(
          :result_case =>    JOB_ORDER_ENTRY_RESULT_CASE[:broken] , 
          :item_id     =>  @component_1_item_1.id   , 
          :is_replaced =>  false   , 
          :description =>   "Awesome"
      )
      
      @joe_1.errors.size.should_not ==  0
    end
    
    it 'should allow broken replacement with compatibliity' do
      @joe_1.update_inspection_result(
          :result_case =>   JOB_ORDER_ENTRY_RESULT_CASE[:broken]  , 
          :item_id     =>  @item_3.id    , 
          :is_replaced =>  true   , 
          :description =>   "Awesome"
      )
      
      @joe_1.errors.size.should_not ==  0
    end
    
    it 'should not allow item with no compatibility' do
      @joe_1.update_inspection_result(
          :result_case =>   JOB_ORDER_ENTRY_RESULT_CASE[:broken]  , 
          :item_id     =>  @component_1_item_1.id    , 
          :is_replaced =>  true   , 
          :description =>   "Awesome"
      )
      
      @joe_1.errors.size.should ==  0
    end
    
    context 'prepare the job_order_entry for confirmation' do
      before(:each) do
        @joe_1.update_inspection_result(
            :result_case =>   JOB_ORDER_ENTRY_RESULT_CASE[:ok]  , 
            :item_id     =>  nil    , 
            :is_replaced =>  false   , 
            :description =>   "Awesome"
        )
        
        @joe_2.update_inspection_result(
            :result_case =>   JOB_ORDER_ENTRY_RESULT_CASE[:broken]  , 
            :item_id     =>  @component_2_item_1.id    , 
            :is_replaced =>  true   , 
            :description =>   "Awesome"
        )
        @job_order.reload 
      end
      
      it 'should update inspection successfully' do
        @joe_1.errors.size.should == 0 
        @joe_2.errors.size.should == 0 
      end
      
      it 'should create valid_result_case @joe_1' do
        # puts "\n\n ====================> Valid Result Case 1 <============== \n\n"
        
        # puts "joe_1 result_case : #{@joe_1.result_case}"
        @joe_1.valid_result_case?.should be_true
        @joe_1.errors.size.should == 0
      end
      
      it 'should create valid_result_case @joe_2' do
        # puts "\n\n ====================> Valid Result Case  1<============== \n\n"
        
        # puts "joe_2 result_case : #{@joe_2.result_case}"
        @joe_2.valid_result_case?.should be_true
        @joe_2.errors.messages.each {|x| puts "msg: #{x}"}
        @joe_2.errors.size.should == 0
      end
      
      
      it 'should not allow confirmation' do
        @job_order.confirm
        @job_order.is_confirmed.should be_false # because we have no ready item 
        @job_order.errors.size.should_not == 0 
        # @job_order.errors.messages.each {|x| puts "job_order_entry_spec msg: #{x}"}
      end
      
      context "create ready item to confirm the job order " do
        before(:each) do
          @sa = StockAdjustment.create_object(
            :adjusted_at  => @adjusted_at,  
            :warehouse_id => @wh_1.id ,  
            :description  => "The adjustment description",  
            :code         => "ADJ234"
          )
          
          @quantity = 5 
          @sae = StockAdjustmentEntry.create_object(
            :stock_adjustment_id => @sa.id ,
            :item_id => @component_2_item_1.id ,
            :actual_quantity => @quantity
          )
          @sa.reload
          @sa.confirm
          @component_2_item_1.reload 
          @job_order.reload 
        end
        
        it 'should produce ready item ' do
          @component_2_item_1.ready.should == @quantity
        end
        
        it 'should allow job order confirmation' do
          @job_order.confirm
          @job_order.errors.messages.each {|x| puts "msg: #{x}"}
          @job_order.is_confirmed.should be_true 
          @component_2_item_1.reload 
          @component_2_item_1.ready.should == @quantity -1 
        end
        
        context "confirming the job order" do
          before(:each) do
            @job_order.confirm
            @joe_1.reload
            @joe_2.reload
          end
          
          it 'should create stock_mutation entry' do
            @joe_1.stock_mutation.should be_nil
            @joe_2.stock_mutation.should be_valid
          end
          
          context "job order unconfirm" do
            before(:each) do
              @job_order.unconfirm
              @joe_1.reload
              @joe_2.reload
              @component_2_item_1.reload
            end
            
            it 'should delete stock_mutation' do
              @component_2_item_1.ready.should == @quantity
            end
            
            it 'should delete the stock_mtation' do
              @joe_1.stock_mutation.should be_nil
              @joe_2.stock_mutation.should be_nil 
            end
          end
        end
        
        
      end
        
  
  
    end
    
  end
end
