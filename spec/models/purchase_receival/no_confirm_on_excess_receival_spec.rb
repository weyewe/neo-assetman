require 'spec_helper'

describe PurchaseReceivalEntry do
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
    
    @prec = PurchaseReceival.create_object(
      :supplier_id => @supplier.id ,
      :received_at => @received_at,
      :code => "REC3424"
    )
    
    
################ create first PO 
    @po.confirm
    @po.reload
    @poe.reload 
    @received_quantity = 2
    @prec_e = PurchaseReceivalEntry.create_object(
      :purchase_receival_id => @prec.id ,
      :purchase_order_entry_id => @poe.id,
      :quantity => @received_quantity ,
      :supplier_id => @supplier.id 

    )
    
    @prec_2 = PurchaseReceival.create_object(
      :supplier_id => @supplier.id ,
      :received_at => @received_at,
      :code => "REC3424haha"
    )
    
    @prec_e_2 = PurchaseReceivalEntry.create_object(
      :purchase_receival_id => @prec_2.id ,
      :purchase_order_entry_id => @poe.id,
      :quantity => @quantity ,
      :supplier_id => @supplier.id 
    )
    
    
    # @prec.confirm
  end
  
  it 'should create prec_2 and prec_e_2' do
    @prec_2.should be_valid 
    @prec_e_2.should be_valid 
  end
  
  context 'confirming the prec' do
    before(:each) do
      @poe.reload
      @initial_poe_pending_receival = @poe.pending_receival
      @initial_poe_received = @poe.received
      
      @prec.reload
      @prec.confirm 
      @prec_e.reload 
      @poe.reload
      @po.reload 
    end
    
    it 'should reduce the pending_receival in the po entry' do
      final_poe_pending_receival = @poe.pending_receival
      final_poe_received = @poe.received
      
      diff_pending_receival  = final_poe_pending_receival - @initial_poe_pending_receival
      diff_received = final_poe_received - @initial_poe_received
      
      diff_pending_receival.should == -1*( @received_quantity)
      diff_received.should == @received_quantity 
    end
    
    
    it 'should not allow prec_2 confirmation' do
      @prec_2.confirm
      @prec_2.is_confirmed.should be_false 
      @prec_2.errors.size.should_not == 0 
      
      # @prec_2.errors.messages.each do |msg|
      #   puts "msg: #{msg}"
      # end
    end
    
    
  end
   
end
