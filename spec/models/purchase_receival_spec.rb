require 'spec_helper'

describe PurchaseReceival do
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
    
    
    @purchased_at = DateTime.new(2012,10,5,0,0,0)
    @received_at  = DateTime.new( 2012,12,5,0,0,0)
    
    
    @po = PurchaseOrder.create_object(
      :supplier_id => @supplier.id ,
      :warehouse_id => @wh_1.id ,
      :description => "The description",
      :code => "PO1234",
      :purchased_at => @purchased_at
    )
    
    @quantity = 5 
    @poe = PurchaseOrderEntry.create_object(
      :purchase_order_id => @po.id ,
      :item_id => @item_1.id ,
      :quantity => @quantity
    )
  end
  
  it 'should set valid initial data' do
    @po.should be_valid
    @poe.should be_valid 
  end
  
  it 'should be allowed to create purchase receival' do
    @prec = PurchaseReceival.create_object(
      :supplier_id => @supplier.id ,
      :received_at => @received_at,
      :code => "REC3424"
    )
    @prec.should be_valid 
  end
  
  context "creating purchase receival" do
    before(:each) do
      @receive_code =  "REC3424"
      @prec = PurchaseReceival.create_object(
        :supplier_id => @supplier.id ,
        :received_at => @received_at ,
        :code => @receive_code
      )  
    end
    
    it 'should create purchase receival' do
      @prec.should be_valid 
    end
    
    it 'should allow deletion' do
      @prec.delete_object
      @prec.persisted?.should be_false 
    end
    
    it 'should allow update' do
      @prec.update_object(
        :supplier_id => @supplier.id ,
        :received_at => @received_at,
        :code => @receive_code
      )
      
      @prec.errors.size.should == 0 
    end
    
    it 'should not allow confirmation' do
      @prec.confirm
      @prec.is_confirmed.should be_false 
      @prec.errors.size.should_not ==0  
    end
  end
  
end
