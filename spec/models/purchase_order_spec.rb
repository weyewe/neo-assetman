require 'spec_helper'

describe PurchaseOrder do
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
  end
end
