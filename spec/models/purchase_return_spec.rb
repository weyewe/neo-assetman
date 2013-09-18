require 'spec_helper'

describe PurchaseReturn do
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
    @returned_at = DateTime.new( 2013,1,5,0,0,0)
    
    
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
    @po.confirm 
    @poe.reload 
    @receive_code = 'REC1344'
    
    @prec = PurchaseReceival.create_object(
      :supplier_id => @supplier.id ,
      :received_at => @received_at ,
      :code => @receive_code
    ) 
    
    @received_quantity = 2
    @prec_e = PurchaseReceivalEntry.create_object(
      :purchase_receival_id => @prec.id ,
      :purchase_order_entry_id => @poe.id,
      :quantity => @received_quantity ,
      :supplier_id => @supplier.id 
    )
    
    @prec.confirm 
    
    @po.reload
    @poe.reload 
    @prec_e.reload 
  end
   
  it 'should initialize correctly' do
    @prec.should be_valid 
    @prec_e.should be_valid 
    @po.should be_valid
    @poe.should be_valid 
  end
  
  it 'should be allowed to create purchase return' do
    @return_code = "RET2342"
    @pret = PurchaseReturn.create_object(
      :supplier_id => @supplier.id ,
      :received_at => @returned_at ,
      :code => @return_code
    )
    
    @pret.should be_valid 
  end
  
  
  
  context "created purchase return" do
    before(:each) do
      @return_code = "RET2342"
      @pret = PurchaseReturn.create_object(
        :supplier_id => @supplier.id ,
        :received_at => @returned_at ,
        :code => @return_code
      )
    end
    
    it 'should be updatable' do
      @pret.update_object(
          :supplier_id => @supplier.id ,
          :received_at => @received_at,
          :code => @receive_code + "234"
      )
      
      @pret.should be_valid 
      @pret.errors.size.should == 0 
    end

    it 'should be deletable' do
      @pret.delete_object
      @pret.persisted?.should be_false 
    end
    
    it 'should not be confirmable' do
      @pret.confirm
      @pret.is_confirmed.should be_false
      @pret.errors.size.should_not == 0 
    end
    
     
    
  end
  
end
