class CreateCompatibilities < ActiveRecord::Migration
  def change
    create_table :compatibilities do |t|  
      t.integer :item_id
      t.integer :component_id 

      t.timestamps
    end
  end
end
