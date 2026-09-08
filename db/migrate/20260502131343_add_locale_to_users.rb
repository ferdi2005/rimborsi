class AddLocaleToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :locale, :string, default: 'it' unless column_exists?(:users, :locale)
    User.update_all(locale: 'it') if User.exists?
  end
end
