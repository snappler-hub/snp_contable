class LedgerMove < ActiveRecord::Base
  belongs_to :ledger_entry
  belongs_to :ledger_account
  belongs_to :ledger_currency

  attr_accessible :currency_ratio, :dh, :value, :ledger_account, :ledger_currency, :currency_ratio

  def value=(val)
    if val.is_a? Numeric
      write_attribute :value_int, (val * 100).to_i
    else
      raise "El valor debe ser un numero"
    end
  end

  def value
    value_int = read_attribute :value_int
    value_int / 100.0
  end
end
