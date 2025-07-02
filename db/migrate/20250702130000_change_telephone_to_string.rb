class ChangeTelephoneToString < ActiveRecord::Migration[7.2]
  def change
    change_column :users, :telephone, :string
  end
end
