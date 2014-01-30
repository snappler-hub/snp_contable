class LedgerMove < ActiveRecord::Base
  belongs_to :ledger_entry
  belongs_to :ledger_account
  belongs_to :ledger_currency

  attr_accessible :currency_ratio, :dh, :value, :ledger_account, :ledger_currency, :currency_ratio

  DIVISOR = 100.0

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
