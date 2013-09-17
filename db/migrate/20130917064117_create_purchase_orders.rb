class CreatePurchaseOrders < ActiveRecord::Migration
  def change
    create_table :purchase_orders do |t|
      
      t.integer :supplier_id 
      t.datetime :purchased_at 
      t.integer :warehouse_id 
      
      t.text :description 
      
      
      t.boolean :is_confirmed, :default => false 
      t.datetime :confirmed_at 
      t.string :code 
      
      
      

      t.timestamps
    end
  end
end
