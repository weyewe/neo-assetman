class CreateStockAdjustmentEntries < ActiveRecord::Migration
  def change
    create_table :stock_adjustment_entries do |t|
      
      t.integer :stock_adjustment_id 
      
      t.integer :item_id 
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
