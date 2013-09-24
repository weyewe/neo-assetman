require 'spec_helper'

describe JobOrder do
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
  end
  
  
  it 'should create job order' do
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
    
    @job_order.should be_valid 
  end
  
  context "creating jb order" do
    before(:each) do
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
    
    it 'should create job order entries' do
      expected_entries_count = @job_order.job_order_entries.count 
      actual_entries_count = 2 #from component1 and component 2
      calculated_from_machine_count = @job_order.asset.machine.components.count 
      
      expected_entries_count.should == actual_entries_count
      expected_entries_count.should == calculated_from_machine_count
    end
    
    it 'should be updatable' do
      
      @job_order.update_object(
        :customer_id  => @customer.id,
        :warehouse_id => @wh_1.id,
        :asset_id     => @asset.id,
        :employee_id  => @employee.id,
        :code         => 'JO.3321',
        :description  => "Butuh perbaikan. tidak dingin. awesome",
        :order_date   => @order_date,
        :case         => JOB_ORDER_CASE[:emergency]
      )
      
      @job_order.errors.size.should == 0 
    end
    
    it 'should be deletable' do
      @job_order.delete_object
      @job_order.persisted?.should be_false 
      
      JobOrderEntry.count.should == 0
    end
    
    it 'should not be confirmable' do
      @job_order.confirm 
      @job_order.is_confirmed.should be_false 
      
      @job_order.errors.size.should_not == 0 
      
    end
  end
  
end
