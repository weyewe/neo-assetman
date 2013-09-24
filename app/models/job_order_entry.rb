class JobOrderEntry < ActiveRecord::Base
  has_one :stock_mutation,  :as => :stock_mutation_source
  
  belongs_to :job_order
  belongs_to :component 
  belongs_to :item 
  
  def self.has_confirmed_replacement_component_entry?(component)
    self.where(
      :component_id => component.id,
      :result_case => JOB_ORDER_ENTRY_RESULT_CASE[:broken],
      :is_replaced => true ,
      :is_confirmed => true 
    ).count != 0 
  end
  
  
  def self.create_object(params)
    new_object = self.new 
    new_object.job_order_id = params[:job_order_id]
    new_object.component_id = params[:component_id]
    
    new_object.save 
  end
  
  def update_object( params ) 
  end
  
  def delete_object
  end
  
  def valid_result_case?
    # puts "The result case: #{self.result_case}"
    if result_case.nil? 
      self.errors.add(:result_case, "Harus ada hasil inspeksi") 
      return false
    end
    
    if not [
      JOB_ORDER_ENTRY_RESULT_CASE[:ok],
      JOB_ORDER_ENTRY_RESULT_CASE[:broken]
    ].include?(result_case) 
      self.errors.add(:result_case, "Hasil inspeksi harus: ok atau rusak")
      return false 
    end
    
    return true 
  end
  
  def valid_is_replaced_item_id_pair?
    if is_replaced.nil? 
      self.errors.add(:is_replaced, "Harus di isi")
      return false 
    end
    
    if not is_replaced? and not item_id.nil?
      self.errors.add(:item_id, "Tidak ada penggantian item")
      return false 
    end
    
    if is_replaced? and item_id.nil?
      self.errors.add(:item_id, "Harus memilih item pengganti")
      return false 
    end
    
    if is_replaced? and not item_id.nil?
      begin
        Item.find item_id  
         
        if self.component.compatibilities.where(:item_id => item_id).length == 0 
          self.errors.add(:item_id, "Tidak ada kompatibilitas")
          return false 
        end
      rescue
        self.errors.add(:item_id, "Harus memilih item") 
        return false 
      end
    end
    
    return true 
    
  end
  
  def valid_inspection_result?
    generic_errors_array = []
    
    if not valid_result_case? 
      puts "invalid result case"
      msg = "Hasil inspeksi harus: ok atau rusak"
      generic_errors_array << msg
    else
      if result_case == JOB_ORDER_ENTRY_RESULT_CASE[:ok]
        if not item_id.nil?
          msg = "Tidak boleh ada penggantian component"
          self.errors.add(:item_id, msg)
          generic_errors_array  << msg 
        end

        if is_replaced?
          msg = "Tidak boleh ada penggantian component"
          self.errors.add(:is_replaced, msg )
          generic_errors_array  << msg 
        end
      end

      if result_case  == JOB_ORDER_ENTRY_RESULT_CASE[:broken]
        if is_replaced?
          if item_id.nil? 
            msg = "Harus memilih penggantian item untuk komponen #{component.name}"
            self.errors.add(:item_id, msg)
            generic_errors_array  << msg 
          else
            if self.component.compatibilities.where(:item_id => item_id).count == 0 
              msg = "Harus compatible dengan komponen #{component.name}"
              self.errors.add(:item_id, msg)
              generic_errors_array  << msg 
            end
          end
        else # if not replaced
          
          if not item_id.nil?
            msg = "Tidak ada penggantian"
            self.errors.add(:item_id, msg)
            generic_errors_array  << msg 
          end
        end
      end
    end
    
    if self.errors.size != 0 
      # puts "\n\n =========> inside valid_inspection_result? total error: #{self.errors.size}"
      # puts "total generic_errors_array: #{generic_errors_array.length}"
      # self.errors.messages.each {|x| puts "msg: #{x}"}
      # puts "generic_errors_message: #{generic_errors_array}"
      
      # puts "\n ======= end of the inspect\n\n"
      
      self.errors.add(:generic_errors, generic_errors_array.join(' | '))
      return false
    else
      return true 
    end
  end
  
  def update_inspection_result(params)
    self.result_case = params[:result_case]
    self.item_id = params[:item_id]
    self.is_replaced = params[:is_replaced]
    self.description = params[:description]
    
    
    if self.valid_inspection_result? 
      self.save
    end
  
    return self 
  end
  
  
  def delete_object
    if self.is_confirmed?
      self.errors.add(:generic_errors, "Sudah dikonfirmasi")
      return self 
    end
    
    self.destroy 
  end
  
  
  def warehouse_item
    return nil if item.nil?
    
    WarehouseItem.find_or_create_object(
      :warehouse_id => self.job_order.warehouse_id, 
      :item_id => self.item_id 
    )
  end
  
  
  def can_be_confirmed?
    
    if valid_inspection_result?
      
      if not warehouse_item.nil? and warehouse_item.ready < 1
        self.errors.add(:generic_errors, "Tidak ada spare part untuk mengganti component #{component.name}")
      end
    end
    
    if self.errors.size != 0 
      puts "inside job_order_entry.can_be_confirmed? the message: #{self.errors.messages}"
      
      return false 
    else
      return true 
    end
    
  end
  
  
  
  def confirm
    return if self.is_confirmed? 
    return self if not self.can_be_confirmed? 
     
    self.is_confirmed = true 
    self.confirmed_at = DateTime.now 
    if self.save 
      if not item_id.nil?
        StockMutation.create_job_order_entry_mutation( self ) 
      end
    end
  end
  
  
   
   
=begin
  effect of purchase return confirm: received deduct , pending_receival add
  effect of purchase return unconfirm: received add, pending_receival negative 
=end
  def can_be_unconfirmed? 
  # the reverse adjustment will always increase ready item 
  
    return true 
  end
  
  
  def unconfirm
    return if not self.is_confirmed? 
    
    return self if not self.can_be_unconfirmed? 
    
    
    self.stock_mutation.delete_object   if not self.stock_mutation.nil?
    self.is_confirmed = false
    self.save
  end
end
