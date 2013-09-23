class CreateJobOrders < ActiveRecord::Migration
  def change
    create_table :job_orders do |t|
      t.integer :customer_id 
      t.integer :asset_id 
      t.integer :warehouse_id 
      t.integer :employee_id 
      
      t.integer :case , :default => JOB_ORDER_CASE[:maintenance]
      
      t.text :description 
      
      t.boolean :is_confirmed, :default => false 
      t.datetime :confirmed_at 
      t.string :code 

      t.timestamps
    end
  end
end
