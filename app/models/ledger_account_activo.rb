class LedgerAccountActivo < LedgerAccount

  def saldo
    dh_hash = get_debe_haber
    debe = dh_hash["D"].to_i
    haber = dh_hash["H"].to_i

    puts "soy activo #{debe + haber}"
  end
end
