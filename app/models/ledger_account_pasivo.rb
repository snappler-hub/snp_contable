class LedgerAccountPasivo < LedgerAccount

	def process_balance(debe, haber) 
		haber - debe
	end
end
