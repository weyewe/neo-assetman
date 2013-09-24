require 'spec_helper'

describe Asset do
  before(:each) do
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
    
    @component = Component.create_object(
      :machine_id => @machine_1.id,
      :name => @component_name_1 
    )
    
    
    @item_1_name = "Item1"
    @item_2_name = "Item2"
    @item_1_code = "faewf"
    @item_2_code = "HS234"
    
    @item_1 = Item.create_object(
      :name =>  @item_1_name,
      :code => @item_1_code
    )
    
    @item_2 = Item.create_object(
      :name => @item_2_name ,
      :code => @item_2_code
    )
    
    @machine_1.reload
    @machine_2.reload
    @component.reload 
    @item_1.reload
    @item_2.reload 
    
    @customer = Customer.create_object(
      :name => "Customer1"
    )
    
    @customer.reload 
  end
  
  it 'should create asset' do
    @asset_1_code = "hh234"
    @asset = Asset.create_object(
      :customer_id => @customer.id, 
      :machine_id => @machine_1.id ,
      :code => @asset_1_code
    )
    
    @asset.errors.size.should == 0 
    @asset.should be_valid 
  end
  
  it 'should not create asset if no customer id, no machine id or no code' do
    
    @asset_1_code = "hh234"
    @asset = Asset.create_object(
      :customer_id => 0 , 
      :machine_id => @machine_1.id ,
      :code => @asset_1_code
    )
    
    @asset.should_not be_valid
    
    @asset = Asset.create_object(
      :customer_id => @customer.id  , 
      :machine_id => 0 ,
      :code => @asset_1_code
    )
    
    @asset.should_not be_valid
    
    @asset = Asset.create_object(
      :customer_id => @customer.id, 
      :machine_id => @machine_1.id ,
      :code => ""
    )
    
    @asset.should_not be_valid
  end
  
  context "creating asset" do
    before(:each) do
      @asset_1_code = "hh234"
      @asset = Asset.create_object(
        :customer_id => @customer.id, 
        :machine_id => @machine_1.id ,
        :code => @asset_1_code
      )
    end
    
    it 'should maintain unique asset code' do
      @asset_1_code = "hh234"
      @asset_2 = Asset.create_object(
        :customer_id => @customer.id, 
        :machine_id => @machine_1.id ,
        :code => @asset_1_code
      )
      
      @asset_2.errors.size.should_not == 0 
      @asset_2.should_not be_valid 
    end
    
    
    it 'should be updatable' do
      @asset.update_object(
        :customer_id => @customer.id,
        :machine_id => @machine_2.id, 
        :code => @asset_1_code
      )
      @asset.errors.size.should == 0 
      @asset.should be_valid 
    end
    
    it 'should be deletable' do
      @asset.delete_object
      @asset.persisted?.should be_false 
    end
  end
end
