class LedgerAccount < ActiveRecord::Base

  belongs_to :contable, polymorphic: true
  belongs_to :master_ledger_account, class_name: "LedgerAccount" 
  has_many   :child_ledger_accounts, class_name: "LedgerAccount", foreign_key: "master_ledger_account_id"
  has_many   :ledger_moves, dependent: :destroy
  belongs_to :owner, polymorphic: true

  validates :master_ledger_account_id, presence: true
  validates :code_name, uniqueness: {scope: [:owner_id, :owner_type]}

  #before_save :set_code
  #after_create :set_order_column

  default_scope { order('order_column ASC') }

  # def self.account(value)
  #   where(:code_name => value.to_s.snp_underscore).first
  # end

  def has_ledger_moves?
    ledger_moves.any?
  end

  def self.account(value)
    find_by(code_name: value.to_s.snp_underscore)
  end

  # def add_child(name, code_name=nil)
  #   if self.persisted?    
  #     if(code_name.nil?)
  #       self.class.create(name: name, master_ledger_account: self )    
  #     else
  #       self.class.create(name: name, code_name: code_name, master_ledger_account: self )    
  #     end
  #   else
  #     if self.errors.count > 0
  #       errores = " La cuenta '#{name}' no se pudo persistir porque sus campos no cumplen la validacion de LedgerAccount."
  #     end
  #     raise "La instancia debe estar persistida para poder agregar una cuenta hija." + errores.to_s
  #   end
  # end

  def add_child(name, code_name=nil)
    if persisted?
      if code_name.nil?
        self.class.create(owner: self.owner, name: name, master_ledger_account: self)    
      else
        self.class.create(owner: self.owner, name: name, code_name: code_name, master_ledger_account: self)    
      end
    else
      errores = ["La instancia debe estar persistida para poder agregar una cuenta hija."]
      errores << "La cuenta '#{name}' no se pudo persistir porque sus campos no cumplen la validacion de LedgerAccount." if errors.any?
      raise errores.join(' ')
    end
  end

  # def add_child_with_contable(name, code_name, contable)
  #   if self.persisted?    
  #     self.class.create(name: name, master_ledger_account: self, contable: contable, code_name: "#{code_name}_#{contable.class.name.underscore}_#{contable.id}"  )    
  #   else
  #     if self.errors.count > 0
  #       errores = " La cuenta '#{name}' no se pudo persistir porque sus campos no cumplen la validacion de LedgerAccount."
  #     end
  #     raise "La instancia debe estar persistida para poder agregar una cuenta hija." + errores.to_s
  #   end
  # end

  def add_child_with_contable(name, code_name, contable)
    if persisted?    
      self.class.create(owner: self.owner, name: name, master_ledger_account: self, contable: contable, code_name: "#{code_name}_#{contable.class.name.underscore}_#{contable.id}"  )    
    else
      errores = ["La instancia debe estar persistida para poder agregar una cuenta hija."]
      errores << "La cuenta '#{name}' no se pudo persistir porque sus campos no cumplen la validacion de LedgerAccount." if errors.any?
      raise errores.join(' ')
    end
  end

  def root?
    master_ledger_account_id == 0
  end

  # def set_code
  #   unless self.master_ledger_account_id == 0
  #     unless self.order_column.nil?
  #       self.code = "#{self.master_ledger_account.code}.#{self.order_column}"
  #     end
  #   end
  # end

  def set_code
    unless root? || order_column.nil?
      self.code = "#{master_ledger_account.code}.#{order_column}"
    end
  end

  # def re_code(parent_code)
  #   self.code = "#{parent_code}#{parent_code.blank? ? '' : '.'}#{order_column}"
  #   save
  #   child_ledger_accounts.each do |child|
  #     child.re_code(code)
  #   end
  # end

  def re_code(parent_code)
    recode(parent_code)
  end

  def recode(parent_code)
    self.code = [parent_code, order_column].compact.join '.'
    save
    child_ledger_accounts.each do |child|
      child.recode(code)
    end
  end

  #def name=(value)
  #  write_attribute :name, value
  #  if (read_attribute(:code_name)).blank?
  #    name_value = read_attribute(:name)
  #    write_attribute :code_name, name_value.snp_underscore
  #  end    
  #end

  def name
    internal_name
  end

  def name=(value)
    self.internal_name = value
    self.code_name = value.snp_underscore if code_name.blank?
  end

  # def set_order_column
  #   #Solo agrega orden si la cuenta no es tope del arbol
  #   unless self.master_ledger_account_id == 0
  #     max = self.master_ledger_account.child_ledger_accounts.maximum(:order_column)
  #   else
  #     max = LedgerAccount.where(:master_ledger_account_id => 0).maximum(:order_column)
  #   end
  #   if max.nil?
  #     self.order_column = 1
  #   else
  #     self.order_column = max + 1
  #   end
  #   self.save
  # end

  def set_order_column
    # Sólo agrega orden si la cuenta no es tope del arbol
    if root?
      max = LedgerAccount.where(master_ledger_account_id: 0).maximum(:order_column)
    else      
      max = master_ledger_account.child_ledger_accounts.maximum(:order_column)
    end

    self.order_column = (max || 0) + 1
  #  save
  end

  def children_accounts_ids
    SnapplerContable.account_sub_tree(self).collect{|account| account.id}
  end

  # def saldo
  #   #alias para compatibilidad
  #   balance
  # end
  def saldo
    balance
  end

  # # Mejora la logica
  # def special_balance(params)
  #   from_date = params[:from_date]
  #   to_date = params[:to_date]
  #   format_value = (params[:format_value].nil?)? true : params[:format_value]
  #   
  #   if((from_date.nil?) && (to_date.nil?))
  #     return balance(format_value)
  #   else
  #     if((! from_date.nil?) && (! to_date.nil?))
  #       return balance_from_to(from_date, to_date, format_value)
  #     else
  #       if(! from_date.nil?)
  #         return balance_from(from_date, format_value)
  #       else
  #         return balance_to(to_date, format_value)
  #       end
  #     end
  #   end
  # end

  # TODO: Mejorar la lógica
  def special_balance(params)
    from_date    = params[:from_date]
    to_date      = params[:to_date]
    format_value = params[:format_value] || true
    
    if from_date.nil? && to_date.nil?
      balance(format_value)
    elsif from_date.present? && to_date.present?
      balance_from_to(from_date, to_date, format_value)
    elsif from_date.present?
      balance_from(from_date, format_value)
    else
      balance_to(to_date, format_value)
    end
  end

  def balance(format_value=true)
    bal = LedgerAccount.where(id: children_accounts_ids).sum(:balance_sum)    
    (format_value)? LedgerMove.format_value(bal) : bal
  end

  # def balance(format_value=true)
  #   balance_sum = child_ledger_accounts(true).sum(:balance_sum)
  #   format_value ? LedgerMove.format_value(balance_sum) : balance_sum
  # end

  # def balance_to(to_date, format_value=true)
  #   dh_hash = LedgerMove.where(:ledger_account_id => children_accounts_ids).where('date <= ?', to_date).group(:dh).sum(:value)
  #   debe = dh_hash["D"].to_i
  #   haber = dh_hash["H"].to_i   
  #   (format_value)? LedgerMove.format_value(process_balance(debe, haber)) : process_balance(debe, haber)
  # end

  def children_moves
    LedgerMove.where(ledger_account_id: children_accounts_ids)
  end

  def process(dh_hash)
    debe  = dh_hash["D"].to_i
    haber = dh_hash["H"].to_i   
    format_value ? LedgerMove.format_value(process_balance(debe, haber)) : process_balance(debe, haber)
  end

  def balance_to(to_date, format_value=true)
    process(children_moves.where('date <= ?', to_date).group(:dh).sum(:value))
  end

  # def balance_from(from_date, format_value=true)
  #   dh_hash = LedgerMove.where(:ledger_account_id => children_accounts_ids).where('date >= ?', from_date).group(:dh).sum(:value)
  #   debe = dh_hash["D"].to_i
  #   haber = dh_hash["H"].to_i   
  #   (format_value)? LedgerMove.format_value(process_balance(debe, haber)) : process_balance(debe, haber)
  # end

  def balance_from(from_date, format_value=true)
    process(children_moves.where('date >= ?', from_date).group(:dh).sum(:value))
  end

  # def balance_from_to(from_date, to_date, format_value=true)
  #   dh_hash = LedgerMove.where(:ledger_account_id => children_accounts_ids).where('date >= ? AND date <= ?', from_date, to_date).group(:dh).sum(:value)
  #   debe = dh_hash["D"].to_i
  #   haber = dh_hash["H"].to_i   
  #   (format_value)? LedgerMove.format_value(process_balance(debe, haber)) : process_balance(debe, haber)
  # end    

  def balance_from_to(from_date, to_date, format_value=true)
    process(children_moves.where('date >= ? AND date <= ?', from_date, to_date).group(:dh).sum(:value))
  end

  def process_balance
    raise "Este metodo solo se tiene que implementar en las subclases"
  end

  # def update_balance(value, dh, ledger_currency)
  #   case dh.upcase
  #   when 'D'
  #     update_balance = process_balance(value, 0)  
  #   when 'H'
  #     update_balance = process_balance(0, value)  
  #   end   
  #   bal = self.balance_sum
  #   self.balance_sum = bal + update_balance
  #   self.save
  # end

  def update_balance(value, dh, ledger_currency)
    balance_update = case dh.upcase
      when 'D' then process_balance(value, 0)  
      when 'H' then process_balance(0, value)  
    end
    self.balance_sum = balance_sum + balance_update
    save
  end

  def update_balance_destroy(value, dh, ledger_currency)
    #inverse operation
    ops = {'D' => 'H', 'H' => 'D'}
    update_balance(value, ops[dh], ledger_currency)
  end

  def accounts_tree
    SnapplerContable.account_sub_tree(self)
  end                     

end