class MoveProjectFromExpenseToReimboursement < ActiveRecord::Migration[7.2]
  def up
    add_column :reimboursements, :project, :string

    # Migrate data
    Reimboursement.reset_column_information
    Expense.reset_column_information

    Reimboursement.find_each do |reimboursement|
      projects = reimbursement.expenses.pluck(:project).compact.reject(&:blank?).uniq
      if projects.any?
        reimboursement.update_column(:project, projects.join(' / '))
      end
    end

    remove_column :expenses, :project
  end

  def down
    add_column :expenses, :project, :string
    remove_column :reimboursements, :project
  end
end
