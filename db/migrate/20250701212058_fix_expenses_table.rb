class FixExpensesTable < ActiveRecord::Migration[7.2]
  def change
    # Rimuovi la foreign key se esiste
    if foreign_key_exists?(:expenses, :reimboursments)
      remove_foreign_key :expenses, :reimboursments
    end

    # Rinomina la colonna reimboursment_id in reimboursement_id
    rename_column :expenses, :reimboursment_id, :reimboursement_id

    # Aggiungi la foreign key corretta
    add_foreign_key :expenses, :reimboursements

    # Rendi opzionali le foreign key che non servono sempre
    change_column_null :expenses, :project_id, true
  end
end
