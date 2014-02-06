class LedgerMove < ActiveRecord::Base
  #--------------------------------------------- RELATION
  belongs_to :ledger_entry
  belongs_to :ledger_account
  belongs_to :ledger_currency  
  #--------------------------------------------- MISC
  attr_accessible :currency_ratio, :dh, :value, :ledger_account, :ledger_currency, :currency_ratio
  DIVISOR = 100.0  
  #--------------------------------------------- VALIDATION

  #--------------------------------------------- CALLBACK
  after_create :update_balance_create
  after_destroy :update_balance_destroy
  after_update :update_balance_update

  #--------------------------------------------- SCOPES

  #--------------------------------------------- METHODS  

  def update_balance_create
    self.ledger_account.update_balance(value, dh)
  end

  def update_balance_destroy
    self.ledger_account.update_balance_destroy(value, dh)
  end  

  def update_balance_update    
    self.ledger_account.update_balance_destroy( self.class.format_value(value_was), dh)
    self.ledger_account.update_balance(value, dh)
  end


  def self.format_value(value)
    value / DIVISOR
  end

  def self.unformat_value(value)    
    (value * DIVISOR).to_i
  end  

  def value=(val)
    if val.is_a? Numeric
      write_attribute :value, self.class.unformat_value(val)
    else
      raise "El valor debe ser un numero"
    end
  end

  def value
    value_formated = read_attribute :value
    self.class.format_value(value_formated)
  end
end
