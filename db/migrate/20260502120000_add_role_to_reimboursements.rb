class AddRoleToReimboursements < ActiveRecord::Migration[7.2]
  def change
    add_column :reimboursements, :role, :string
    add_column :reimboursements, :role_other, :string
  end
end
