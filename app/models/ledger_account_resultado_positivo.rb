class LedgerAccountResultadoPositivo < LedgerAccount

	def process_balance(debe, haber) 
		debe.merge(haber){|key, oldval, newval| newval - oldval}
	end  
end
