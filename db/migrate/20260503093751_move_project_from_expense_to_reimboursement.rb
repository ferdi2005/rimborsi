class MoveProjectFromExpenseToReimboursement < ActiveRecord::Migration[7.2]
  def up
    if column_exists?(:reimboursements, :project)
      change_column :reimboursements, :project, :text
    else
      add_column :reimboursements, :project, :text
    end

    add_reference :reimboursements, :fund, foreign_key: true unless column_exists?(:reimboursements, :fund_id)

    # Migrate data
    Reimboursement.reset_column_information
    Expense.reset_column_information

    Reimboursement.find_each do |reimboursement|
      projects = reimboursement.expenses.pluck(:project).compact.reject(&:blank?).uniq
      if projects.size == 1
        reimboursement.update_column(:project, projects.first)
      elsif projects.size > 1
        reimboursement.update_column(:project, projects.join(" / "))
      end

      # Popola il progetto sulle spese del rimborso che ne sono prive se il rimborso ha un progetto
      if reimboursement.project.present?
        reimboursement.expenses.where(project: [nil, ""]).update_all(project: reimboursement.project)
      end

      fund_ids = reimboursement.expenses.pluck(:fund_id).compact.uniq
      if fund_ids.size == 1
        reimboursement.update_column(:fund_id, fund_ids.first)
      elsif fund_ids.size > 1
        puts "Rimborso ##{reimboursement.id} ha spese su fondi multipli (#{fund_ids.join(', ')}). fund_id rimane nullo per preservare lo storico."
      end
    end
  end

  def down
    remove_reference :reimboursements, :fund, foreign_key: true if column_exists?(:reimboursements, :fund_id)
    remove_column :reimboursements, :project if column_exists?(:reimboursements, :project)
  end
end
