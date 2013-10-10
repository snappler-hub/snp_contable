module SnapplerContable
  module SnapplerContableActiveRecordExtension


    def self.included(base)  
      base.extend ClassMethods  
    end  

    # add your static(class) methods here
    module ClassMethods

      #act_as_snappler_contable(:accounts => [:acc_1, :acc_2],\n
      #               :account_by_operation => {:oper_1 => :acc_1,\n
      #                                         :oper_2 => :acc_2})\n      
      def act_as_snappler_contable(config_hash = nil)
        if config_hash.nil? or config_hash.class.to_s != "Hash"
          raise "\nError en la declaracion de act_as_snappler_contable en la clase #{name}\nUso de act_as_snappler_contable:\n      #act_as_snappler_contable(:accounts => [:acc_1, :acc_2],\n      #               :account_by_operation => {:oper_1 => :acc_1,\n      #                                         :oper_2 => :acc_2})\n"
        end
        @snappler_contable_active = true
        if config_hash.key? :accounts
          @my_ledger_accounts = config_hash[:accounts]
          @my_ledger_accounts.each do |code_name|
            if LedgerAccount.find_by_code_name(code_name.to_s.snp_underscore).nil?
              raise "La cuenta '#{code_name}' (code_name: '#{code_name.to_s.snp_underscore}') no existe como cuenta contable LedgerAccount"
            end
          end          
        else
          raise "La clase '#{self.class}' no declara cuentas en 'act_as_snappler_contable{:accounts => []}'"
        end

        if config_hash.key? :account_by_operation
          @my_op_account_hash = config_hash[:account_by_operation]
          #chequea que todas las operaciones existan
          valid_ops = SnapplerContable.valid_operations
          @my_op_account_hash.each_pair do |oper, acc|
            unless valid_ops.include? oper
              raise "La clase #{self.name} declara la operacion ':#{oper}', que no existe como operacion valida en 'config/initializers/snappler_contable.rb'"
            end
            unless @my_ledger_accounts.include? acc
              raise "La clase #{self.name} indica: ':#{oper} => :#{acc}', pero la cuenta '#{acc}' no esta incluida en 'act_as_snappler_contable{:accounts => []}'"
            end
          end          
        else
          raise "La clase '#{self.class}' no declara cuenta por operacion en 'act_as_snappler_contable{:account_by_operation => []}'"
        end

      end



      def get_my_accounts_by_operation
        @my_op_account_hash
      end    

      def get_my_ledger_accounts
        @my_ledger_accounts
      end

      def get_snappler_contable_active
        @snappler_contable_active
      end

    end

    def snappler_contable_active?
      self.class.get_snappler_contable_active
    end    

    def get_name_and_code_name(ledger_account_code_name)
      name_aux = ledger_account_code_name.to_s
      name_aux += " "
      name_aux += self.class.to_s
      name_aux += " "
      code_name_aux = name_aux

      name_aux += (self.respond_to?(:name)) ? self.name : self.id.to_s
      code_name_aux += self.id.to_s

      code_name_aux = code_name_aux.snp_underscore

      return name_aux, code_name_aux
    end

    def get_ledger_account_by_operation(operation)

      if SnapplerContable.valid_operations.include? operation
        ledger_account_code_name = self.class.get_my_accounts_by_operation[operation]
        return get_ledger_account(ledger_account_code_name)
      else
        raise "La operacion ':#{operation.to_s}' no esta incluida como valid_operation en 'config/initializers/snappler_contable.rb'"
      end
    end

    def get_ledger_account(ledger_account_code_name)
      if self.class.get_my_ledger_accounts.include? ledger_account_code_name
        if self.persisted?
          name_aux, code_name_aux = get_name_and_code_name(ledger_account_code_name)
          res_ledger_account = LedgerAccount.find_by_code_name(code_name_aux)
          if res_ledger_account.nil?
          #no existe la cuenta relacionada, se crea
          master_ledger_account = LedgerAccount.find_by_code_name(ledger_account_code_name.to_s)
          if not master_ledger_account.nil?
            #uso la clase del padre para crear la cuenta de objeto
            res_ledger_account = master_ledger_account.class.create(name: name_aux, code_name: code_name_aux, master_ledger_account: master_ledger_account, contable: self )
            return res_ledger_account
          else
            raise  "No existe la cuenta padre #{ledger_account_code_name.to_s}"
          end
        else
          #se devuelve la cuenta relacionada
          return res_ledger_account
        end
      else
        raise  "El objeto de clase #{self.class} aun no esta persistido, no tiene cuenta #{ledger_account_code_name.to_s} asociada"
      end
    else
      raise  "La clase '#{self.class.titleize}' no esta vinculada a la cuenta #{ledger_account_code_name.to_s}"
    end
  end
  
end
end