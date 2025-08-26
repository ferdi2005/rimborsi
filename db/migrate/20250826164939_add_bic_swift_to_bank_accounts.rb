class AddBicSwiftToBankAccounts < ActiveRecord::Migration[7.2]
  def change
    add_column :bank_accounts, :bic_swift, :string
  end
end
