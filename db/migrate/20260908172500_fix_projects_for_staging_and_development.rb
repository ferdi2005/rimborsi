class FixProjectsForStagingAndDevelopment < ActiveRecord::Migration[7.2]
  def up
    # Questa migrazione serve per riallineare i dati su staging e development
    # dove la migrazione originale era già stata applicata in precedenza.
    # In produzione la migrazione originale farà già l'allineamento corretto.
    return if Rails.env.production?

    Reimboursement.reset_column_information
    Expense.reset_column_information

    Reimboursement.find_each do |reimboursement|
      projects = reimboursement.expenses.pluck(:project).compact.reject(&:blank?).uniq

      if projects.any?
        reimboursement.update_column(:project, projects.join(" / "))
      elsif reimboursement.project.blank?
        fallback = reimboursement.fund&.name || "Non assegnato"
        reimboursement.update_column(:project, fallback)
      end

      if reimboursement.project.present?
        reimboursement.expenses.where(project: [nil, ""]).update_all(project: reimboursement.project)
      end
    end
  end

  def down
    # Nessuna operazione distruttiva di rollback
  end
end
