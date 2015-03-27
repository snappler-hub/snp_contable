module SnapplerContable
  class << self

    def default_currency
      LedgerCurrency.find_by_code(@my_default_currrency)
    end

    def default_currency=(default_currency)
      @my_default_currrency = default_currency
    end

    def valid_operations
      @my_valid_operations
    end

    def valid_operations=(operations)
      @my_valid_operations = operations
    end

    # def self.accounts_tree
    #   tree = TreeNode.new(nil, true)
    #   tree.add_child_ledger_accounts(root_accounts)
    #   return tree
    # end
    #
    # def self.account_sub_tree(ledger_account)
    #   tree = TreeNode.new(nil, true)
    #   tree.add_child_ledger_accounts([ledger_account])
    #   return tree
    # end

    def root_accounts
      LedgerAccount.where(master_ledger_account_id: 0)
    end

    def new_tree(children)
      tree = TreeNode.new(nil, true)
      tree.add_accounts(children)
      return tree
    end
  
    def accounts_tree
      new_tree(root_accounts)
    end
  
    def account_sub_tree(ledger_account)
      new_tree([ledger_account])
    end

    # def self.re_code_tree
    #   LedgerAccount.where(:master_ledger_account_id => 0).each do |account|
    #     account.re_code('')
    #   end
    # end

    def recode_tree
      root_accounts.each {|account| account.recode('')}
    end
    alias_method :re_code_tree, :recode_tree

    def extract_accounts(moves_array, operation, debe_haber)
  
      res_accounts = []
      moves_array.each do |move|
        move[:dh] = debe_haber
        if move.key? :account
          acc = move[:account]
          if (acc.class.to_s == 'LedgerAccount') or (acc.class.superclass.to_s == 'LedgerAccount')
            res_accounts << move
          else
            if move.key? :operation
              oper = move[:operation]
            else
              oper = operation
            end
            if oper.nil?
              raise "No se puede extraer la cuenta del objeto #{acc.class.to_s} con operation == nil"
            else
              unless acc.nil?
                if acc.respond_to? "get_ledger_account_by_operation"
                  move[:account] = acc.get_ledger_account_by_operation(oper)
                  res_accounts << move
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

    def op(array_debe, array_haber, params_hash)
      operation_debe = params_hash[:operation_debe]
      operation_haber = params_hash[:operation_haber]
      date = params_hash[:date]
  
      #if operation_haber.nil?
      #  operation_haber = operation_debe
      #end
      operation_haber ||= operation_debe
  
      #TODO Verificar si viene el mismo objeto en el debe y el haber y pedir DOS operaciones
      debe_accounts  = extract_accounts(array_debe,  operation_debe,  'D')
      haber_accounts = extract_accounts(array_haber, operation_haber, 'H')
  
      total_debe  =  debe_accounts.inject(0){|init, move| init + move[:value] }
      total_haber = haber_accounts.inject(0){|init, move| init + move[:value] }
      # TODO: probar siguiente:
      # total_debe  =  debe_accounts.sum {|move| move[:value]}
      # total_haber = haber_accounts.sum {|move| move[:value]}
  
      if total_haber != total_debe
        raise "Las sumas del DEBE y HABER son diferentes - debe: #{total_debe} haber: #{total_haber}"
      end
  
      moves = debe_accounts + haber_accounts
  
      #verificando si todos los movimientos tienen orden
      #if all_moves.inject(true){|res, move| res & (move.key? :order)}
      #  all_moves.sort!{|a, b| a[:order] <=> b[:order]}
      #end
      if moves.all?{|move| move.key? :order}
        moves.sort!{|a, b| a[:order] <=> b[:order]}
      end
  
      dc = SnapplerContable.default_currency
  
      entry = LedgerEntry.create
      moves.each do |m|
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
        entry.ledger_moves.build(ledger_account: m[:account], value: m[:value], dh: m[:dh], ledger_currency: m[:currency], currency_ratio: m[:currency_ratio], date: date)
      end
  
      if entry.save
        entry
      else
        entry.destroy
        raise "Fallo la creacion del movimiento: #{moves}"
      end
    end
  end

end