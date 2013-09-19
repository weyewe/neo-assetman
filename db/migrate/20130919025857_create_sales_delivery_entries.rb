class CreateSalesDeliveryEntries < ActiveRecord::Migration
  def change
    create_table :sales_delivery_entries do |t|
      
      t.integer :sales_delivery_id  
      t.integer :quantity , :default => 0 # quantity received
      
      t.integer :sales_order_entry_id 
      
      t.integer :warehouse_id 
      
      t.boolean :is_confirmed, :default => false 
      t.datetime :confirmed_at 
      t.string :code

      t.timestamps
    end
  end
end
