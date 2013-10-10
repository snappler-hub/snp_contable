
module SnapplerContable

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

  def self.re_code_tree
    LedgerAccount.where(:master_ledger_account_id => 0).each do |account|
      account.re_code('')
    end
  end

  def self.extract_accounts(accounts_array, operation)
    res_accounts = []
    accounts_array.each do |acc|
      if (acc.class.to_s == 'LedgerAccount') or ((acc.class.superclass.to_s == 'LedgerAccount'))
        res_accounts << acc
      else
        if operation.nil?
          raise "No se puede extraer la cuenta del objeto #{acc.class.to_s} con operation == nil"
        else
          unless acc.nil?
            if acc.respond_to? "snappler_contable_active?"
              if acc.snappler_contable_active?
                res_accounts << acc.get_ledger_account_by_operation(operation)
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
    end
    return res_accounts
  end

  def self.op(array_debe, array_haber, operation = nil)
    debe_accounts = extract_accounts(array_debe, operation)
    haber_accounts = extract_accounts(array_haber, operation)
    puts "DEBE -------------------------------------------------------"
    debe_accounts.each do |da|
      puts "#{da.code_name} - #{da.class.to_s}"
    end
    puts "HABER ------------------------------------------------------"
    haber_accounts.each do |da|
      puts "#{da.code_name} - #{da.class.to_s}"
    end
    puts "OPER -------------------------------------------------------"
    puts operation.to_s
    return 'OK'
  end  

end
