class MoveProjectFromExpenseToReimboursement < ActiveRecord::Migration[7.2]
  def up
    add_column :reimboursements, :project, :string
    add_reference :reimboursements, :fund, foreign_key: true

    # Migrate data
    Reimboursement.reset_column_information
    Expense.reset_column_information

    Reimboursement.find_each do |reimboursement|
      projects = reimboursement.expenses.pluck(:project).compact.reject(&:blank?).uniq
      if projects.any?
        reimboursement.update_column(:project, projects.join(' / '))
      end

      fund_ids = reimboursement.expenses.pluck(:fund_id).compact.uniq
      if fund_ids.size == 1
        reimboursement.update_column(:fund_id, fund_ids.first)
      elsif fund_ids.size > 1
        puts "Rimborso ##{reimboursement.id} ha spese su fondi multipli (#{fund_ids.join(', ')}). fund_id rimane nullo per preservare lo storico."
      end
    end

    remove_column :expenses, :project
  end

  def down
    add_column :expenses, :project, :string
    remove_reference :reimboursements, :fund, foreign_key: true
    remove_column :reimboursements, :project
  end
end
