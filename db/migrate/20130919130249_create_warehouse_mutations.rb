class CreateWarehouseMutations < ActiveRecord::Migration
  def change
    create_table :warehouse_mutations do |t|
      
      t.integer :source_warehouse_id
      t.integer :target_warehouse_id
      t.datetime :mutated_at 
      t.text :description 
      
      t.boolean :is_confirmed , :default => false 
      t.string :code 
      t.datetime :confirmed_at
      

      t.timestamps
    end
  end
end
