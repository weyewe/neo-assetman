class CreatePurchaseReturnEntries < ActiveRecord::Migration
  def change
    create_table :purchase_return_entries do |t|

      t.timestamps
    end
  end
end
