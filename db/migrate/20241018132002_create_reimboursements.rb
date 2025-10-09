class CreateReimboursements < ActiveRecord::Migration[7.2]
  def change
    create_table :reimboursements do |t|
      t.bigint :user_id, null: false
      t.bigint :bank_account_id, null: false
      t.bigint :paypal_account_id, null: false

      t.timestamps
    end

    add_foreign_key :reimboursements, :users
    add_foreign_key :reimboursements, :bank_accounts
    add_foreign_key :reimboursements, :paypal_accounts
  end
end
