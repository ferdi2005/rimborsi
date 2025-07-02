class AddBankNameToBankAccounts < ActiveRecord::Migration[7.2]
  def change
    add_column :bank_accounts, :bank_name, :string
  end
end
