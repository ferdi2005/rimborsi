class CleanupNonAssegnatoProjects < ActiveRecord::Migration[7.2]
  def up
    # Rimuove 'Non assegnato' dai progetti su staging e development
    return if Rails.env.production?

    Reimboursement.reset_column_information
    Expense.reset_column_information

    Reimboursement.where(project: "Non assegnato").update_all(project: nil)
    Expense.where(project: "Non assegnato").update_all(project: nil)

    Reimboursement.find_each do |reimboursement|
      projects = reimboursement.expenses.pluck(:project).compact.reject(&:blank?).uniq
      if projects.any?
        reimboursement.update_column(:project, projects.join(" / "))
        reimboursement.expenses.where(project: [nil, ""]).update_all(project: reimboursement.project)
      end
    end
  end

  def down
  end
end
