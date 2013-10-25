class SnapplerContableMigrate < ActiveRecord::Migration
  def self.up
    create_table :ledger_accounts do |t|
      t.string :name
      t.string :code
      t.string :code_name
      t.integer :order_column
      t.references :contable, :polymorphic => true
      t.integer :master_ledger_account_id
      t.string :type

      t.timestamps
    end
    add_index :ledger_accounts, :contable_id

    #Las primeras 5 deben existir
    aa = LedgerAccountActivo.create(name: 'Activo', code: '1', master_ledger_account_id: '0')
    ap = LedgerAccountPasivo.create(name: 'Pasivo', code: '2', master_ledger_account_id: '0')
    apn = LedgerAccountPatrimonioNeto.create(name: 'Patrimonio Neto', code: '3', master_ledger_account_id: '0')
    arp = LedgerAccountResultadoPositivo.create(name: 'Resultado Positivo', code: '4', master_ledger_account_id: '0')
    arn = LedgerAccountResultadoNegativo.create(name: 'Resultado Negativo', code: '5', master_ledger_account_id: '0')

    #Estas son solo de ejemplo
    activo_corriente = LedgerAccountActivo.create(name: 'Activo Corriente', master_ledger_account: aa )
    disponibilidades = LedgerAccountActivo.create(name: 'Disponibilidades', master_ledger_account: activo_corriente )
    proveedores = LedgerAccountActivo.create(name: 'Proveedores', master_ledger_account: disponibilidades )    


    create_table :ledger_moves do |t|
      t.references :ledger_entry
      t.references :ledger_account
      t.string :dh, :limit => 1
      t.integer :value_int, :default => 0
      t.integer :value_dec, :default => 0
      t.references :ledger_currency
      t.float :currency_ratio

      t.timestamps
    end
    add_index :ledger_moves, :ledger_entry_id
    add_index :ledger_moves, :ledger_account_id
    add_index :ledger_moves, :ledger_currency_id

    create_table :ledger_entries do |t|
      t.timestamps
    end

    create_table :ledger_currencies do |t|
      t.string :name
      t.string :code

      t.timestamps
    end    
    LedgerCurrency.create(name: 'Peso', code: 'ARS')

  end

  def self.down
    drop_table :ledger_accounts
    drop_table :ledger_moves
    drop_table :ledger_entries
    drop_table :ledger_currencies
  end
end
