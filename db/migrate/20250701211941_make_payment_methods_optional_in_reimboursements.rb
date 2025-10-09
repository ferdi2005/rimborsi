class MakePaymentMethodsOptionalInReimboursements < ActiveRecord::Migration[7.2]
  def change
    change_column_null :reimboursements, :bank_account_id, true
  end
end
