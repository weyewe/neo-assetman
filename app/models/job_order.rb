class JobOrder < ActiveRecord::Base
  belongs_to :customer
  belongs_to :employee 
  belongs_to :asset 
  belongs_to :warehouse
  belongs_to :employee 
  
  has_many :job_order_entries 
  
  validates_presence_of :customer_id, :warehouse_id, :asset_id, :employee_id , :case, :order_date 
  validate :valid_customer_id
  validate :valid_warehouse_id
  validate :valid_asset_id
  validate :valid_employee_id
  validate :valid_case 
  
  
  def all_fields_present?
    customer_id.present? and 
    warehouse_id.present? and 
    asset_id.present? and 
    employee_id.present? 
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
  
  def valid_warehouse_id
    return if not self.all_fields_present? 
    
    begin
       Warehouse.find warehouse_id   
    rescue
      self.errors.add(:warehouse_id, "Harus memilih gudang") 
      return self 
    end
  end
  
  def valid_asset_id
    return if not self.all_fields_present? 
    
    begin
       Asset.find asset_id   
    rescue
      self.errors.add(:asset_id, "Harus memilih aset") 
      return self 
    end
  end
  
  def valid_employee_id
    return if not self.all_fields_present? 
    
    begin
       Employee.find employee_id   
    rescue
      self.errors.add(:employee_id, "Harus memilih karyawan") 
      return self 
    end
  end
  
  def valid_case
    return if not self.all_fields_present? 
    
    [
      JOB_ORDER_CASE[:maintenance],
      JOB_ORDER_CASE[:emergency]
      ].include?(self.case)
  end
  
  
  def create_job_order_entries
    self.job_order_entries.each {|x| x.delete_object}
    
    self.asset.machine.components.each do |component|
      JobOrderEntry.create_object(
          :job_order_id => self.id, 
          :component_id => component.id 
      )
    end
    
  end
  
  def self.create_object( params ) 
    new_object = self.new 
    
    new_object.customer_id  = params[:customer_id ]
    new_object.warehouse_id = params[:warehouse_id ]
    new_object.asset_id     = params[:asset_id     ]
    new_object.employee_id  = params[:employee_id  ]
    new_object.code         = params[:code]
    new_object.description  = params[:description]
    new_object.order_date = params[:order_date]
    
    new_object.case = params[:case]
    if new_object.save 
      new_object.create_job_order_entries
    end
    
    return new_object 
    
  end
  
  def update_object( params )
    if self.is_confirmed?
      self.errors.add(:generic_errors, 'Sudah konfirmasi')
      return self 
    end
    
    self.customer_id  = params[:customer_id ]
    self.warehouse_id = params[:warehouse_id ]
    self.asset_id     = params[:asset_id     ]
    self.employee_id  = params[:employee_id  ]
    self.code         = params[:code]
    self.description  = params[:description]
    self.order_date = params[:order_date]

    self.case = params[:case]
    if self.save
      self.create_job_order_entries 
    end
    
  end
  
  def confirm
    # puts "Calling the confirm"
    
    return if self.is_confirmed? 
    if self.job_order_entries.count == 0 
      self.errors.add(:generic_errors, "Tidak ada job order entry. silakan tambah")
      return self 
    end
    
    
    self.job_order_entries.each do |joe|
      if not joe.can_be_confirmed? 
        # puts "=================\n\n"
        # puts "joe.errors.messages.to_s: #{joe.errors.messages.to_s } " 
        # joe.errors.messages.each do |msg|
        #   # puts "The msg: #{msg}"
        #   puts msg.to_s
        # end
        # puts "in the job_order#confirm. generic_errors: #{joe.errors.messages[:generic_errors]}"
        self.errors.add(:generic_errors, joe.errors.messages[:generic_errors].first)
        return self
      end
    end
    
    self.job_order_entries.each {|x| x.confirm }
    
    
    self.is_confirmed = true 
    self.confirmed_at = DateTime.now
    self.save
  end
  
  def unconfirm
    return if not self.is_confirmed?
    
    self.job_order_entries.each do |joe|
      if not joe.can_be_unconfirmed?
        self.errors.add(:generic_errors, joe.errors.messages[:generic_errors].first)
        return self 
      end
    end

    
    self.is_confirmed = false 
    self.save
    self.job_order_entries.each {|x| x.unconfirm }
  end
  
  def delete_object
    if self.is_confirmed?
      self.errors.add(:generic_errors, 'Sudah konfirmasi')
      return self 
    end
  
    
    self.job_order_entries.each {|x| x.delete_object}
    self.destroy
  end
end
