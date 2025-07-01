class AddStatusChangeToNotes < ActiveRecord::Migration[7.2]
  def change
    # Aggiungi il campo per tracciare il cambio di stato
    add_column :notes, :status_change, :string

    # Rimuovi la relazione con la tabella states se esiste
    remove_foreign_key :notes, :states if foreign_key_exists?(:notes, :states)
    remove_column :notes, :state_id, :bigint if column_exists?(:notes, :state_id)
  end
end
