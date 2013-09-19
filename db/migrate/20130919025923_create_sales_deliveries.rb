class CreateSalesDeliveries < ActiveRecord::Migration
  def change
    create_table :sales_deliveries do |t|

      t.timestamps
    end
  end
end
