class LedgerMove < ActiveRecord::Base
  belongs_to :ledger_entry
  belongs_to :ledger_account
  belongs_to :ledger_currency

  attr_accessible :currency_ratio, :dh

  def value=(val)
    if val.is_a? Integer
      write_attribute :value_int, val
      write_attribute :value_dec, 0
    elsif val.is_a? Float
      parts = val.to_s.split('.')
      write_attribute :value_int, parts.first
      write_attribute :value_dec, parts.last
    else
      raise "El valor debe ser un numero"
    end
  end

  def value
    value_int = read_attribute :value_int
    value_dec = read_attribute :value_dec
    if value_dec == 0
      value_int.to_f
    else
      value_int.to_f + (value_dec.to_f / (('1' + ('0' * value_dec.to_s.size)).to_f))
    end
  end
end
