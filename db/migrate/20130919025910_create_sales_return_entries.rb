class CreateSalesReturnEntries < ActiveRecord::Migration
  def change
    create_table :sales_return_entries do |t|
      
      t.integer :sales_return_id 
      t.integer :quantity , :default => 0 # quantity returned
      
      t.integer :sales_order_entry_id 
      
      t.boolean :is_confirmed, :default => false 
      t.datetime :confirmed_at 
      t.string :code
      t.timestamps
    end
  end
end
