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
    
    
    # create StockAdjustment 
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
    
    @sa.confirm 
    
    
    
    @component_2_item_1.reload 
  end
  
  it 'should create @component_2_item_1.ready' do
    @component_2_item_1.ready.should_not == 0 
  end
  
  context "confirming the first job order" do
    before(:each) do
      # first job order: confirm it
      # second job order : dont' confirm 
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

      @joe_1 = @job_order.job_order_entries.where(:component_id => @component_1.id).first
      @joe_2 = @job_order.job_order_entries.where(:component_id => @component_2.id).first

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
      @job_order.confirm 

      @joe_1.reload 
      @joe_2.reload
      @component_2_item_1.reload 
    end
    
    it 'should confirm job order' do
      @job_order.is_confirmed.should be_true 
      @joe_1.is_confirmed.should be_true
      @joe_2.is_confirmed.should be_true 

      @component_2_item_1.ready.should == @quantity -1 
    end
    
    
    context "creating second job order" do
      before(:each) do
        @job_order_2 = JobOrder.create_object(
          :customer_id  => @customer.id,
          :warehouse_id => @wh_1.id,
          :asset_id     => @asset.id,
          :employee_id  => @employee.id,
          :code         => 'JO.3321',
          :description  => "Butuh perbaikan. tidak dingin.",
          :order_date   => @order_date,
          :case         => JOB_ORDER_CASE[:emergency]
        )

        @joe2_1 = @job_order_2.job_order_entries.where(:component_id => @component_1.id).first
        @joe2_2 = @job_order_2.job_order_entries.where(:component_id => @component_2.id).first
      end
      
      it 'should be unconfirmed' do
        @job_order_2.reload
        @job_order_2.is_confirmed.should be_false 
      end
      
      context "adding new component to the machine" do
        before(:each) do
          @component_name_3 = "Awesome3333"
          @component_3 = Component.create_object(
            :machine_id => @machine_1.id,
            :name => @component_name_3 
          )
          
          @job_order_2.reload 
          @job_order.reload 
        end
        
        it 'should create 3 job order entries for job_order_2' do
          @job_order_2.job_order_entries.count.should == 3 
        end
        
        it 'should preserve 2 job order entries for job order 1' do
          @job_order.job_order_entries.count.should == 2 
        end
        
        context "delete component" do
          before(:each) do
            @component_1.delete_object
          end
          
          it 'should not allow deletion' do
            @component_1.errors.size.should_not == 0
            @component_1.persisted?.should be_true 
          end
          
          it 'should preserve the quantity in job order 1 and 2' do
            @job_order.job_order_entries.count.should == 2 
            @job_order_2.job_order_entries.count.should == 3 
          end
        end
        
      end
    end
    
  end
  
  
  
end
