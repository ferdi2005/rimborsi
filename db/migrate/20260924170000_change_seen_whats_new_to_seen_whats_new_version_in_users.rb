class ChangeSeenWhatsNewToSeenWhatsNewVersionInUsers < ActiveRecord::Migration[7.2]
  def up
    add_column :users, :seen_whats_new_version, :string unless column_exists?(:users, :seen_whats_new_version)

    if column_exists?(:users, :seen_whats_new)
      execute("UPDATE users SET seen_whats_new_version = '1.0' WHERE seen_whats_new = true")
      remove_column :users, :seen_whats_new
    end
  end

  def down
    add_column :users, :seen_whats_new, :boolean, default: false, null: false unless column_exists?(:users, :seen_whats_new)

    if column_exists?(:users, :seen_whats_new_version)
      execute("UPDATE users SET seen_whats_new = true WHERE seen_whats_new_version IS NOT NULL")
      remove_column :users, :seen_whats_new_version
    end
  end
end
