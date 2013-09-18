class CreatePurchaseReturns < ActiveRecord::Migration
  def change
    create_table :purchase_returns do |t|

      t.timestamps
    end
  end
end
