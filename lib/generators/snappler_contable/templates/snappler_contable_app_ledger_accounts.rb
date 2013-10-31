class SnapplerContableAppLedgerAccounts < ActiveRecord::Migration
  def self.up
    activo = LedgerAccountActivo.first
    # sub_cuenta_activo_1 = activo.add_child("Sub Cuenta Activo 1")
    # sub_cuenta_activo_2 = activo.add_child("Sub Cuenta Activo 2")
    #   sub_sub_cuenta_activo = sub_cuenta_activo_2.add_child("Sub Sub Cuenta Activo 1")

    pasivo = LedgerAccountPasivo.first
    patrimonio_neto = LedgerAccountPatrimonioNeto.first
    resultado_positivo = LedgerAccountResultadoPositivo.first
    resultado_negativo = LedgerAccountResultadoNegativo.first
  end

  def self.down
    LedgerAccount.destroy_all("master_ledger_account_id <> 0")
  end
end