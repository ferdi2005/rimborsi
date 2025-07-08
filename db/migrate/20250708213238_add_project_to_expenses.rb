class AddProjectToExpenses < ActiveRecord::Migration[7.2]
  def change
    add_column :expenses, :project, :string
  end
end
