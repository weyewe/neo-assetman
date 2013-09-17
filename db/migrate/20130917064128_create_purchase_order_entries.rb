class CreatePurchaseOrderEntries < ActiveRecord::Migration
  def change
    create_table :purchase_order_entries do |t|
      t.integer :purchase_order_id 
      t.integer :quantity 
      t.integer :item_id 
      

      t.timestamps
    end
  end
end
