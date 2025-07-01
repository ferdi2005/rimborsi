class FixNotesTable < ActiveRecord::Migration[7.2]
  def change
    # Rimuovi la foreign key se esiste
    if foreign_key_exists?(:notes, :reimboursments)
      remove_foreign_key :notes, :reimboursments
    end
    
    # Rinomina la colonna reimboursment_id in reimboursement_id
    rename_column :notes, :reimboursment_id, :reimboursement_id
    
    # Aggiungi la foreign key corretta
    add_foreign_key :notes, :reimboursements
  end
end
