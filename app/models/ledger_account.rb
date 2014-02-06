class LedgerAccount < ActiveRecord::Base
  #--------------------------------------------- RELATIION
  belongs_to :contable, polymorphic: true
  has_many :child_ledger_accounts, :class_name => "LedgerAccount", :foreign_key => "master_ledger_account_id", :order => 'order_column'
  belongs_to :master_ledger_account, :class_name => "LedgerAccount" 
  #--------------------------------------------- MISC
  attr_accessible :name, :code, :code_name, :master_ledger_account_id, :master_ledger_account, :contable, :balance_sum
  #--------------------------------------------- VALIDATION
  validates :master_ledger_account_id, :presence => true
  validates :code_name, :uniqueness => true
  #--------------------------------------------- CALLBACK
  before_save :set_code
  after_create :set_order_column
  #--------------------------------------------- SCOPES
  default_scope order('order_column ASC')
  #--------------------------------------------- METHODS

  def self.account(value)
    where(:code_name => value.to_s.snp_underscore).first
  end

  def add_child(name)
    if self.persisted?    
      self.class.create(name: name, master_ledger_account: self )    
    else
      if self.errors.count > 0
        errores = " La cuenta '#{name}' no se pudo persistir porque sus campos no cumplen la validacion de LedgerAccount."
      end
      raise "La instancia debe estar persistida para poder agregar una cuenta hija." + errores.to_s
    end
  end

  def set_code
    unless self.master_ledger_account_id == 0
      unless self.order_column.nil?
        self.code = "#{self.master_ledger_account.code}.#{self.order_column}"
      end
    end
  end

  def re_code(parent_code)
    self.code = "#{parent_code}#{parent_code.blank? ? '' : '.'}#{order_column}"
    save
    child_ledger_accounts.each do |child|
      child.re_code(code)
    end
  end  

  def name=(value)
    write_attribute :name, value
    if (read_attribute(:code_name)).blank?
      name_value = read_attribute(:name)
      write_attribute :code_name, name_value.snp_underscore
    end    
  end

  def set_order_column
    #Solo agrega orden si la cuenta no es tope del arbol
    unless self.master_ledger_account_id == 0
      max = self.master_ledger_account.child_ledger_accounts.maximum(:order_column)
    else
      max = LedgerAccount.where(:master_ledger_account_id => 0).maximum(:order_column)
    end

    if max.nil?
      self.order_column = 1
    else
      self.order_column = max + 1
    end

    self.save
  end

  def children_accounts_ids
    SnapplerContable.account_sub_tree(self).collect{|account| account.id}
  end

  def saldo
    #alias para compatibilidad
    balance
  end

  def balance
    bal = LedgerAccount.where(:id => children_accounts_ids).sum(:balance_sum)    
    LedgerMove.format_value(bal)
  end


  def balance_to(to_date)
    dh_hash = LedgerMove.where(:ledger_account_id => children_accounts_ids).where('created_at <= ?', to_date.end_of_day).group(:dh).sum(:value)
    debe = dh_hash["D"].to_i
    haber = dh_hash["H"].to_i   
    LedgerMove.format_value(process_balance(debe, haber))
  end

  def balance_from(from_date)
    dh_hash = LedgerMove.where(:ledger_account_id => children_accounts_ids).where('created_at >= ?', from_date.beginning_of_day).group(:dh).sum(:value)
    debe = dh_hash["D"].to_i
    haber = dh_hash["H"].to_i   
    LedgerMove.format_value(process_balance(debe, haber))
  end  

  def balance_from_to(from_date, to_date)
    dh_hash = LedgerMove.where(:ledger_account_id => children_accounts_ids).where('created_at >= ? AND created_at <= ?', from_date.beginning_of_day, to_date.end_of_day).group(:dh).sum(:value)
    debe = dh_hash["D"].to_i
    haber = dh_hash["H"].to_i   
    LedgerMove.format_value(process_balance(debe, haber))
  end    

  def process_balance
    raise "Este metodo solo se tiene que implementar en las subclases"
  end

  def update_balance(value, dh)
    case dh.upcase
    when 'D'
      update_balance = process_balance(value, 0)  
    when 'H'
      update_balance = process_balance(0, value)  
    end   
    bal = self.balance_sum
    self.balance_sum = bal + update_balance
    save
  end

  def update_balance_destroy(value, dh)
    #inverse operation
    ops = {'D' => 'H', 'H' => 'D'}
    update_balance(value, ops[dh])
  end

  def accounts_tree
    SnapplerContable.account_sub_tree(self)
  end                     

  def balance_sum=(val)
    if val.is_a? Numeric
      write_attribute :balance_sum, LedgerMove.unformat_value(val)
    else
      raise "El valor debe ser un numero"
    end
  end

  def balance_sum
    value_formated = read_attribute :balance_sum
    LedgerMove.format_value(value_formated)
  end 

end


