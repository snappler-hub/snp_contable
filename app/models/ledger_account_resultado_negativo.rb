class LedgerAccountResultadoNegativo < LedgerAccount

  def process_saldo(debe, haber) 
    debe - haber
  end  
end