class CreateJobOrderEntries < ActiveRecord::Migration
  def change
    create_table :job_order_entries do |t|
      t.integer :job_order_id 
      t.integer :component_id 
      
      
      # Data Entry for post Inspection: result_case, is_replaced, item_id 
      # result : ok or broken
      t.integer :result_case 
      # , :default => JOB_ORDER_ENTRY_RESULT_CASE[:ok]  # can't be confirmed if there
      # is unconfirmed result case
      
      t.boolean :is_replaced, :default => false 
      t.text :description 
      
      
      t.integer :item_id # in case that it is broken, and need to be replaced: select the replacement
      
      t.boolean :is_confirmed, :default => false 
      t.datetime :confirmed_at 
      t.string :code
      

      t.timestamps
    end
  end
end
