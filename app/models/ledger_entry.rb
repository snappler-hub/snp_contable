class LedgerEntry < ActiveRecord::Base
  has_many :ledger_moves
end
