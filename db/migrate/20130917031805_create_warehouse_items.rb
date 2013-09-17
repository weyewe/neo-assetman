class CreateWarehouseItems < ActiveRecord::Migration
  def change
    create_table :warehouse_items do |t|
      
      t.integer :item_id
      t.integer :warehouse_id 
      
      t.integer :ready, :default => 0 
      t.integer :pending_receival, :default => 0 
      t.integer :pending_delivery , :default => 0

      t.timestamps
    end
  end
end
