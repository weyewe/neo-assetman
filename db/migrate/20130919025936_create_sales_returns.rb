class CreateSalesReturns < ActiveRecord::Migration
  def change
    create_table :sales_returns do |t|

      t.timestamps
    end
  end
end
