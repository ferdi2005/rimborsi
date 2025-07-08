class RemovePaypalAccountFromReimboursements < ActiveRecord::Migration[7.2]
  def change
    remove_reference :reimboursements, :paypal_account, null: false, foreign_key: true
  end
end
