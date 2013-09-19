class CreateSalesReturns < ActiveRecord::Migration
  def change
    create_table :sales_returns do |t|
      t.integer :customer_id 
      t.text :description 
      t.datetime :received_at 
      
      t.boolean :is_confirmed, :default => false 
      t.string :code 
      t.datetime :confirmed_at
      
      t.integer :warehouse_id

      t.timestamps
    end
  end
end
