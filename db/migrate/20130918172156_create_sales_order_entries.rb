class CreateSalesOrderEntries < ActiveRecord::Migration
  def change
    create_table :sales_order_entries do |t|
      
      t.integer :sales_order_id 
      t.integer :quantity , :default => 0 # quantity ordered
      t.integer :pending_delivery
      t.integer :delivered, :default => 0 
      
      t.integer :item_id 
      
      t.boolean :is_confirmed, :default => false 
      t.datetime :confirmed_at 
      t.string :code

      t.timestamps
    end
  end
end
