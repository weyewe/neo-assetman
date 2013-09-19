class CreateSalesDeliveryEntries < ActiveRecord::Migration
  def change
    create_table :sales_delivery_entries do |t|
      t.integer :sales_order_entry_id

      t.timestamps
    end
  end
end
