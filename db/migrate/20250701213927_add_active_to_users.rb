class AddActiveToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :active, :boolean, default: true, null: false

    # Imposta tutti gli utenti esistenti come attivi
    User.update_all(active: true) if table_exists?(:users)
  end
end
