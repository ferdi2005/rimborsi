class CleanupNonAssegnatoProjects < ActiveRecord::Migration[7.2]
  def up
    return if Rails.env.production?

    Reimboursement.reset_column_information
    Expense.reset_column_information

    # Rimuove 'Non assegnato' impostato per errore
    Reimboursement.where("LOWER(TRIM(project)) = ?", "non assegnato").update_all(project: nil)
    Expense.where("LOWER(TRIM(project)) = ?", "non assegnato").update_all(project: nil)

    # Rimuove i valori di progetto che erano stati popolati erroneamente con il nome del fondo
    fund_names = Fund.pluck(:name).compact.reject(&:blank?)
    if fund_names.any?
      Reimboursement.where(project: fund_names).update_all(project: nil)
      Expense.where(project: fund_names).update_all(project: nil)
    end

    # Riallinea il progetto del rimborso solo se le spese avevano un progetto effettivo
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
