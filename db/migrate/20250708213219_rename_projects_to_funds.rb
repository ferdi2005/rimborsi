class RenameProjectsToFunds < ActiveRecord::Migration[7.2]
  def change
    rename_table :projects, :funds
    rename_column :expenses, :project_id, :fund_id
  end
end
