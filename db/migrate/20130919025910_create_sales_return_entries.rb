class CreateSalesReturnEntries < ActiveRecord::Migration
  def change
    create_table :sales_return_entries do |t|
      t.integer :sales_order_entry_id
      t.timestamps
    end
  end
end
