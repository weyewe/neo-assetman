require 'spec_helper'

describe Machine do
  before(:each) do
    @name_1=  "Awesome1"
    @name_2=  "Awesome2"
    @machine = Machine.create_object(
      :name => @name_1 
    )
  end
  
  it 'should create machine' do
    @machine.should be_valid 
  end
  
  it 'should not allow machine with 2 names' do
    @machine_2=   Machine.create_object(
      :name => @name_1 
    )
    
    @machine_2.should_not be_valid 
  end
  
  it 'should be updatable' do
    @machine.update_object(
      :name => @name_2
    )
    @machine.errors.size.should == 0 
    
    @machine_2 = Machine.create_object(
      :name => @name_1
    )
    @machine_2.should be_valid 
  end
  
  it 'should be deletable' do
    @machine.delete_object
    @machine.persisted?.should be_false 
  end
end
