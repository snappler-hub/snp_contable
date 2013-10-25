
module SnapplerContable

  def self.default_currency=(default_currency)
    if ActiveRecord::Base.connection.table_exists? 'ledger_currencies'
      @my_default_currrency = LedgerCurrency.find_by_code(default_currency) 
    else
      @my_default_currrency = nil
    end
  end

  def self.default_currency
    @my_default_currrency
  end

  def self.valid_operations=(operations)
    @my_valid_operations = operations
  end


  def self.valid_operations
    @my_valid_operations
  end 


  def self.accounts_tree
    tree = TreeNode.new(nil, true)
    tree.add_child_ledger_accounts(LedgerAccount.where(:master_ledger_account_id => 0))
    return tree
  end

  def self.account_sub_tree(ledger_account)
    tree = TreeNode.new(nil, true)
    tree.add_child_ledger_accounts([ledger_account])
    return tree
  end

  def self.re_code_tree
    LedgerAccount.where(:master_ledger_account_id => 0).each do |account|
      account.re_code('')
    end
  end

  def self.extract_accounts(moves_array, operation, debe_haber)
    res_accounts = []
    moves_array.each do |move|
      move[:dh] = debe_haber
      if move.key? :account
        acc = move[:account]
        if (acc.class.to_s == 'LedgerAccount') or ((acc.class.superclass.to_s == 'LedgerAccount'))
          res_accounts << move
        else
          if operation.nil?
            raise "No se puede extraer la cuenta del objeto #{acc.class.to_s} con operation == nil"
          else
            unless acc.nil?
              if acc.respond_to? "snappler_contable_active?"
                if acc.snappler_contable_active?
                  move[:account] = acc.get_ledger_account_by_operation(operation)
                  res_accounts << move
                else
                  raise "La clase #{acc.class.to_s} no implementa el modulo contable."
                end 
              else
                raise "La clase #{acc.class.to_s} no implementa el modulo contable."
              end
            else
              raise "Se paso como cuenta un objeto Nil"
            end 
          end      
        end
      else
        raise "El hash de movimiento no tiene :account - #{move}"
      end
      unless move.key? :value
        raise "El hash de movimiento no tiene :value - #{move}"
      end
    end
    return res_accounts
  end

  def self.op(array_debe, array_haber, operation = nil)
    debe_accounts = extract_accounts(array_debe, operation, 'D')
    haber_accounts = extract_accounts(array_haber, operation, 'H')

    total_debe = debe_accounts.inject(0){|init, move| init + move[:value] }
    total_haber = haber_accounts.inject(0){|init, move| init + move[:value] }

    if total_haber != total_debe
      raise "Las sumas del DEBE y HABER son diferentes - debe: #{total_debe} haber: #{total_haber}"
    end

    all_moves = debe_accounts + haber_accounts

    #verificando si todos los movimientos tienen orden
    if all_moves.inject(true){|res, move| res & (move.key? :order)}
      all_moves.sort!{|a, b| a[:order] <=> b[:order]}
    end

    dc = SnapplerContable.default_currency

    le = LedgerEntry.create
    all_moves.each do |m|
      if m.key? :currency
        if m[:currency].is_a? Numeric
          m[:currency] = LedgerCurrency.find(m[:currency]) 
        end
        unless m.key? :currency_ratio
          m[:currency_ratio] = 1
        end
      else
        m[:currency] = dc
        m[:currency_ratio] = 1
      end
      le.ledger_moves.build(ledger_account: m[:account], value: m[:value], dh: m[:dh], ledger_currency: m[:currency], currency_ratio: m[:currency_ratio])
    end

    if le.save
      le
    else
      le.destroy
      raise "Fallo la creacion del movimiento: #{all_moves}"
    end
  end  

end
