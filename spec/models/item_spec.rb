require 'spec_helper'

describe Item do
  before(:each) do
    @wh_1 = Warehouse.create_object(
      :name => "Warehouse 1",
      :description => "Our main warehouse"
    )
    
    @item_1 = Item.create_object(
      :name => "Hose 5m",
      :code => "HS34"
    )
  end
  
  it 'should create item and warehouse' do
    @wh_1.should be_valid
    @item_1.should be_valid
  end
end
