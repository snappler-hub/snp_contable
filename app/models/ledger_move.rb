class LedgerMove < ActiveRecord::Base
  #--------------------------------------------- RELATION
  belongs_to :ledger_entry
  belongs_to :ledger_account
  belongs_to :ledger_currency  
  #--------------------------------------------- MISC
  attr_accessible :currency_ratio, :dh, :value, :ledger_account, :ledger_currency, :currency_ratio, :date
  DIVISOR = 100.0
  #--------------------------------------------- VALIDATION

  #--------------------------------------------- CALLBACK
  after_create :update_balance_create
  after_destroy :update_balance_destroy
  after_update :update_balance_update

  #--------------------------------------------- SCOPES
  scope :filter_date_start, lambda { |date| if((date)&&(! date.blank?))
    {:conditions => ["ledger_moves.date >= ?", Date.parse(date)]}
  end }

  scope :filter_date_end, lambda { |date| if((date)&&(! date.blank?))
    {:conditions => ["ledger_moves.date <= ?", Date.parse(date)]}
  end }

  scope :order_date_asc, :order => 'ledger_moves.date ASC, ledger_moves.id ASC'

  #--------------------------------------------- METHODS  

  def update_balance_create
    self.ledger_account(true).update_balance(raw_value, dh, ledger_currency)
  end


  def update_balance_destroy
    self.ledger_account(true).update_balance_destroy(raw_value, dh, ledger_currency)
  end  


  def update_balance_update    
    self.ledger_account(true).update_balance_destroy(value_was, dh, ledger_currency)
    self.ledger_account(true).update_balance(raw_value, dh, ledger_currency)
  end

  def self.format_hash(bal)
    bal_aux = {}
    bal.each{|x,y|  bal_aux[x] = LedgerMove::format_value(y) }

    bal_sorted = {}
    bal_aux.sort.collect{|elem| bal_sorted[elem.first] = elem.last }

    return bal_sorted
  end

  def self.unformat_hash(bal)
    bal_aux = {}  
    bal.each{|x,y|  bal_aux[x] = LedgerMove::unformat_value(y) }
    
    bal_sorted = {}
    bal_aux.sort.collect{|elem| bal_sorted[elem.first] = elem.last }
    
    return bal_sorted
  end  


  def self.format_value(value)
    value / DIVISOR
  end

  def self.unformat_value(value)    
    (value * DIVISOR).round.to_i
  end  

  def value=(val)
    if val.is_a? Numeric
      write_attribute :value, self.class.unformat_value(val)
    else
      raise "El valor debe ser un numero"
    end
  end

  def currency_with_value(format_value=true)
    case self.dh.upcase
    when 'D'
      bal = self.ledger_account.process_balance({self.ledger_currency_id.to_s => self.raw_value}, {ledger_currency.id.to_s => 0})
    when 'H'
      bal = self.ledger_account.process_balance({ledger_currency.id.to_s => 0}, {self.ledger_currency_id.to_s => self.raw_value})
    end
    bal = LedgerMove::format_hash(bal) if(format_value)
    return bal
  end

  def value
    value_formated = read_attribute :value
    self.class.format_value(value_formated)
  end

  def raw_value
    return read_attribute :value
  end
end
