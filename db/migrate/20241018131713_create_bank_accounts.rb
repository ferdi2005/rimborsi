class CreateBankAccounts < ActiveRecord::Migration[7.2]
  def change
    create_table :bank_accounts do |t|
      t.bigint :user_id, null: false
      t.string :iban
      t.string :owner
      t.string :address
      t.string :cap
      t.string :town
      t.string :fiscal_code
      t.boolean :default

      t.timestamps
    end

    add_foreign_key :bank_accounts, :users
  end
end
