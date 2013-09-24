require 'spec_helper'

describe Compatibility do
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
    
    @component = Component.create_object(
      :machine_id => @machine.id,
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
  end
  
  it 'should create compatibility' do
    @compatibility = Compatibility.create_object(
      :item_id => @item_1.id ,
      :component_id => @component.id 
    )
    
    @compatibility.should be_valid 
  end
  
  it 'should not create compatibility if one of itemid/component_id inexistant' do
    @compatibility = Compatibility.create_object(
      :item_id => 0 ,
      :component_id => @component.id 
    )
    
    @compatibility.should_not be_valid
    
    
    @compatibility = Compatibility.create_object(
      :item_id => @item_1.id ,
      :component_id =>  0
    )
    
    @compatibility.should_not be_valid
    
  end
  
  context "Creating compatibility" do
    before(:each) do
      @compatibility = Compatibility.create_object(
        :item_id => @item_1.id ,
        :component_id => @component.id 
      )
    end
    
    it 'should not allow double compatibility' do
      @compatibility_2 = Compatibility.create_object(
        :item_id => @item_1.id ,
        :component_id => @component.id 
      )
      
      @compatibility_2.errors.size.should_not == 0 
      @compatibility_2.should_not be_valid 
    end
    
    it 'should be deletable' do
      @compatibility.delete_object
      @compatibility.persisted?.should be_false 
    end
    
    it 'should allow update' do
      @compatibility.update_object(
        :item_id => @item_2.id, 
        :component_id => @component.id
      )
      
      @compatibility.errors.size.should ==0 
      @compatibility.should be_valid 
    end
  end
end
