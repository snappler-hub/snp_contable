class LedgerAccountActivo < LedgerAccount

	def process_balance(debe, haber) 
		haber.merge(debe){|key, oldval, newval| newval - oldval}
	end
end


