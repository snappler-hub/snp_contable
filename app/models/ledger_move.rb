class LedgerMove < ActiveRecord::Base

  belongs_to :ledger_entry
  belongs_to :ledger_account
  belongs_to :ledger_currency

  DIVISOR = 100.0

  after_create :update_balance_create
  after_destroy :update_balance_destroy
  after_update :update_balance_update

  #--------------------------------------------- SCOPES
  #scope :filter_date_start, ->(date) { if((date)&&(! date.blank?))
  #  where('ledger_moves.date >= :date', date: Date.parse(date))
  #end }
  scope :filter_date_start, ->(date) { where('ledger_moves.date >= :date', date: Date.parse(date)) if date.present? }

  #scope :filter_date_end, ->(date) { if((date)&&(! date.blank?))
  #  where('ledger_moves.date <= :date', date: Date.parse(date))
  #end }
  scope :filter_date_end, ->(date) { where('ledger_moves.date <= :date', date: Date.parse(date)) if date.present? }

  scope :order_date_asc, -> { order('ledger_moves.date ASC, ledger_moves.id ASC')}


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

  def self.format_value(value)
    value / DIVISOR
  end

  def self.unformat_value(value)    
    (value * DIVISOR).round.to_i
  end  

  def value
    value_formated = read_attribute :value
    self.class.format_value(value_formated)
  end

  def value=(val)
    if val.is_a? Numeric
      write_attribute :value, self.class.unformat_value(val)
    else
      raise "El valor debe ser un numero"
    end
  end

  def raw_value
    return read_attribute :value
  end
end