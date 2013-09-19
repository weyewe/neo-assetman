class CreateSalesDeliveries < ActiveRecord::Migration
  def change
    create_table :sales_deliveries do |t|
      t.integer :customer_id  
      t.text :description 
      t.datetime :delivered_at 
      
      t.boolean :is_confirmed, :default => false 
      t.string :code 
      t.datetime :confirmed_at
      
      t.integer :warehouse_id 
      
      t.integer :warehouse_id 
      

      t.timestamps
    end
  end
end
