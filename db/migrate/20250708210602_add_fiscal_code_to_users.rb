class AddFiscalCodeToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :fiscal_code, :string
  end
end
