class AddLocaleToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :locale, :string, default: 'it'
    User.update_all(locale: 'it') if User.exists?
  end
end
