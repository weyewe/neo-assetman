class CreateStockAdjustments < ActiveRecord::Migration
  def change
    create_table :stock_adjustments do |t|
      t.integer :item_id 
      t.integer :warehouse_id 
      t.integer :warehouse_item_id 
      
      t.integer :actual_quantity, :default => 0 
      t.integer :initial_quantity , :default => 0 
      t.integer :diff, :default => 0  # post-result (auto computed)
      
      t.boolean :is_confirmed , :default => false 
      t.string :code 
      
      t.datetime :confirmed_at 

      t.timestamps
    end
  end
end
