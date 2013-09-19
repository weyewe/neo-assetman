class SalesOrder < ActiveRecord::Base
  has_many :sales_order_entries 
  belongs_to :customer 
  
  
  validates_presence_of :customer_id ,  :code , :sold_at 
  validates_uniqueness_of :code 
  
  validate :valid_customer_id 
  validate :valid_code
  
  def valid_code
    if code.present? and code.length == 0
      self.errors.add(:code, "Harus ada code PO")
      return self 
    end
  end
  
  def all_fields_present?
    customer_id.present? and 
    code.present? 
  end
  
  def valid_customer_id
    return if not self.all_fields_present? 
    
    begin
       Customer.find customer_id   
    rescue
      self.errors.add(:customer_id, "Harus memilih customer") 
      return self 
    end
  end
  
  
  
  
  def self.create_object(params)
    new_object = self.new
    new_object.customer_id = params[:customer_id]
    new_object.sold_at = params[:sold_at]
    new_object.description = params[:description]
    new_object.code  = params[:code]
    
    new_object.save
    return new_object
  end
  
  def update_object(params)
    if self.is_confirmed?
      self.errors.add(:generic_errors, "Sudah konfirmasi, tidak bisa update")
      return self 
    end
    self.customer_id = params[:customer_id]
    self.sold_at = params[:sold_at]
    self.description = params[:description]
    self.code = params[:code]
    self.save
    return self
  end
  
  def delete_object
    if self.is_confirmed?
      self.errors.add(:generic_errors, "Sudah dikonfirmasi")
      return self
    end
    
    if self.sales_order_entries.count != 0
      self.errors.add(:generic_errors, "Sudah ada sales order entry")
      return self 
    end
    
    self.sales_order_entries.each {|x| x.delete_object}
    self.destroy 
  end
  
  def confirm
    return if self.is_confirmed? 
    if self.sales_order_entries.count == 0 
      self.errors.add(:generic_errors, "Tidak ada yang dibeli. silakan tambah pembelian.")
      return self 
    end
    
    
    self.sales_order_entries.each {|x| x.confirm }
    
    
    self.is_confirmed = true 
    self.confirmed_at = DateTime.now
    self.save
    
  end
  
  def unconfirm
    return if not self.is_confirmed?
    
    # puts "\n========> Calling sales_order.unconfirm"
    # self.sales_order_entries.each do |soe|
    #   puts "soe.item.pending_delivery: #{soe.item.pending_delivery}"
    # end
    
    # puts "\n\n"
    self.sales_order_entries.each do |soe|
      if not soe.can_be_unconfirmed?
        
        # puts "sales_order#unconfirm => in the unconfirm"
        # puts "sales_order#unconfirm => the item pending_delivery: #{soe.item.pending_delivery}" 
        
        self.errors.add(:generic_errors, soe.errors.messages[:generic_errors].first)
        return self 
      end
    end

    
    self.is_confirmed = false 
    self.save
    self.sales_order_entries.each {|x| x.unconfirm }
  end
  
end
