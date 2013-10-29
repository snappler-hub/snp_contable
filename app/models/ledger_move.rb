class LedgerMove < ActiveRecord::Base
  belongs_to :ledger_entry
  belongs_to :ledger_account
  belongs_to :ledger_currency

  attr_accessible :currency_ratio, :dh, :value, :ledger_account, :ledger_currency, :currency_ratio

  DIVISOR = 100.0

  def self.format_value(value)
    value / DIVISOR
  end

  def value=(val)
    if val.is_a? Numeric
      write_attribute :value_int, (val * 100).to_i
    else
      raise "El valor debe ser un numero"
    end
  end

  def value
    value_int = read_attribute :value_int
    self.class.format_value(value_int)
  end
end
