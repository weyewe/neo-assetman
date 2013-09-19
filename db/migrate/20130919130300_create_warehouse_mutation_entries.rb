class CreateWarehouseMutationEntries < ActiveRecord::Migration
  def change
    create_table :warehouse_mutation_entries do |t|

      t.timestamps
    end
  end
end
