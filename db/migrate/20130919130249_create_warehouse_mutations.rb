class CreateWarehouseMutations < ActiveRecord::Migration
  def change
    create_table :warehouse_mutations do |t|

      t.timestamps
    end
  end
end
