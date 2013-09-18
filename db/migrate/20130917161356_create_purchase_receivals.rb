class CreatePurchaseReceivals < ActiveRecord::Migration
  def change
    create_table :purchase_receivals do |t| 
      
      t.integer :supplier_id 
      t.text :description 
      t.datetime :received_at 
      
      t.boolean :is_confirmed, :default => false 
      t.string :code 
      t.datetime :confirmed_at 

      t.timestamps
    end
  end
end
