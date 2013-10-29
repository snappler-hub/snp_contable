class LedgerAccountPasivo < LedgerAccount

  def process_saldo(debe, haber) 
    haber - debe
  end
end
