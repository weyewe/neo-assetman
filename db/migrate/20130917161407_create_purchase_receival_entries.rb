class CreatePurchaseReceivalEntries < ActiveRecord::Migration
  def change
    create_table :purchase_receival_entries do |t|

      t.timestamps
    end
  end
end
