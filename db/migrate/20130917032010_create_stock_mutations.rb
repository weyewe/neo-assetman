class CreateStockMutations < ActiveRecord::Migration
  def change
    create_table :stock_mutations do |t|
      
      t.integer :warehouse_item_id 
      t.integer :warehouse_id 
      t.integer :item_id 
      
      t.integer :quantity
      
      t.integer :case , :default => STOCK_MUTATION_CASE[:ready]
      
      t.integer :stock_mutation_source_id 
      t.string :stock_mutation_source_type 
      
      t.datetime :mutated_at 

      t.timestamps
    end
  end
end
