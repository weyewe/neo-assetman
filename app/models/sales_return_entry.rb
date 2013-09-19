class SalesReturnEntry < ActiveRecord::Base
  belongs_to :sales_order_entry 
end
