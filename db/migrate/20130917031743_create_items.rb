class CreateItems < ActiveRecord::Migration
  def change
    create_table :items do |t|
      t.string :name
      t.string :code
      t.text :description 
      
      t.integer :ready, :default => 0 
      t.integer :pending_receival, :default => 0 
      t.integer :pending_delivery , :default => 0 
      
      

      t.timestamps
    end
  end
end
