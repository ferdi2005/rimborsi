class CreateBankAccounts < ActiveRecord::Migration[7.2]
  def change
    create_table :bank_accounts do |t|
      t.references :user, null: false, foreign_key: true, type: :bigint
      t.string :iban
      t.string :owner
      t.string :address
      t.string :cap
      t.string :town
      t.string :fiscal_code
      t.boolean :default

      t.timestamps
    end
  end
end
