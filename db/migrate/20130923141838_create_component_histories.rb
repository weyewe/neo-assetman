class CreateComponentHistories < ActiveRecord::Migration
  def change
    create_table :component_histories do |t|
      t.integer :asset_id 
      t.integer :item_id 
      t.integer :component_id  
       
      t.integer :case , :default => COMPONENT_HISTORY_CASE[:default]
      t.integer :job_order_entry_id 
      
      t.boolean :is_active, :default => true 

      t.timestamps
    end
  end
end
