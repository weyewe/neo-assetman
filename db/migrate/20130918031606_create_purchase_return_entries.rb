class CreatePurchaseReturnEntries < ActiveRecord::Migration
  def change
    create_table :purchase_return_entries do |t|
      t.integer :purchase_return_id 
      t.integer :quantity , :default => 0 # quantity returned
      
      t.integer :purchase_order_entry_id 
      
      t.boolean :is_confirmed, :default => false 
      t.datetime :confirmed_at 
      t.string :code
      
      
      t.timestamps
    end
  end
end
