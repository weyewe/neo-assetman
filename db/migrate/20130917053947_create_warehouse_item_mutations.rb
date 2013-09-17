class CreateWarehouseItemMutations < ActiveRecord::Migration
  def change
    create_table :warehouse_item_mutations do |t|
      
      t.integer :source_warehouse_id
      t.integer :target_warehouse_id 
      
      t.integer :quantity 
      t.integer :item_id 
      
      t.boolean :is_confirmed , :default => false 
      t.string :code 
      t.datetime :confirmed_at 

      t.timestamps
    end
  end
end
