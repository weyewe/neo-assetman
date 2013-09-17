class CreatePurchaseReceivals < ActiveRecord::Migration
  def change
    create_table :purchase_receivals do |t| 

      t.timestamps
    end
  end
end
