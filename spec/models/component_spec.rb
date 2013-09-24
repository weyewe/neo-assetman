require 'spec_helper'

describe Component do
  before(:each) do
    @name_1=  "Awesome1"
    @machine = Machine.create_object(
      :name => @name_1 
    )
    @name_2 =  "Awesome2"
    @machine_2 = Machine.create_object(
      :name => @name_2 
    )
    @component_name_1 = "Component1"
    @component_name_2 = "Component2"
  end
  
  it 'should be allowed to create component' do
    @component = Component.create_object(
      :machine_id => @machine.id,
      :name => @component_name_1 
    )
    
    @component.should be_valid
  end
  
  it 'should not create if there is no name or no machine_id' do
    @component = Component.create_object(
      :machine_id => @machine.id,
      :name => "" 
    )
    
    @component.should_not be_valid
    
    @component = Component.create_object(
      :machine_id => 0,
      :name => @component_name_1 
    )
    
    @component.should_not be_valid
  end
  
  context "created component" do
    before(:each) do
      @component = Component.create_object(
        :machine_id => @machine.id,
        :name => @component_name_1 
      )
    end
    
    it 'should create component' do
      @component.should be_valid 
    end
    
    it 'should create the derivative: component history and job order entries (N/A)'
    
    it 'should not preserve unique component name in a given machine' do
      @component_2 = Component.create_object(
        :machine_id => @machine.id,
        :name => @component_name_1 
      )
      
      @component_2.errors.size.should_not == 0 
      @component_2.should_not be_valid 
    end
    
    it 'should be updatable' do
      @component.update_object(
        :machine_id => @machine.id, 
        :name => @component_name_2 
      )
      
      @component.errors.size.should == 0 
      @component.should be_valid 
    end
    
    it 'should be deletable' do
      @component.delete_object
      @component.persisted?.should be_false 
    end
  end
  
  
end
