class CreateWarehouseMutationEntries < ActiveRecord::Migration
  def change
    create_table :warehouse_mutation_entries do |t|
      t.integer :warehouse_mutation_id 
      
      t.integer :quantity 
      t.integer :item_id 
      
      t.boolean :is_confirmed , :default => false 
      t.string :code 
      t.datetime :confirmed_at

      t.timestamps
    end
  end
end
