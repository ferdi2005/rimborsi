class AddSeenWhatsNewToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :seen_whats_new, :boolean, default: false, null: false unless column_exists?(:users, :seen_whats_new)
  end
end
