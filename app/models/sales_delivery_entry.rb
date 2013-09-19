class SalesDeliveryEntry < ActiveRecord::Base
  belongs_to :sales_order_entry 
end
