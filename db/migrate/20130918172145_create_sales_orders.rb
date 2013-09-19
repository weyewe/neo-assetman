class CreateSalesOrders < ActiveRecord::Migration
  def change
    create_table :sales_orders do |t|
      
      
      # we are not tracking the warehouse id 
      # it can come from any source. Listed in the DeliveryOrder 
      
      t.integer :customer_id 
      t.datetime :sold_at 
      
      t.text :description 
      
      
      t.boolean :is_confirmed, :default => false 
      t.datetime :confirmed_at 
      t.string :code 
      
      

      t.timestamps
    end
  end
end
