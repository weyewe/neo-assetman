class CreateAssets < ActiveRecord::Migration
  def change
    create_table :assets do |t|
      t.string :code
      t.integer :customer_id 
      t.integer :machine_id 

      t.timestamps
    end
  end
end
