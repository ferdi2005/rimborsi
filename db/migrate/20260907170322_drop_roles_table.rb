class DropRolesTable < ActiveRecord::Migration[7.2]
  def change
    remove_reference :users, :role, foreign_key: true
    drop_table :roles do |t|
      t.string :label
      t.timestamps
    end
  end
end
