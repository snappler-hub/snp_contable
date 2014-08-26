class LedgerAccountActivo < LedgerAccount

	def process_balance(debe, haber) 
		debe - haber
	end
end
