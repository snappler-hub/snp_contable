class LedgerAccountResultadoNegativo < LedgerAccount

	def process_balance(debe, haber) 
		debe - haber
	end  
end