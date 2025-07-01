class AddStatusToReimboursementsAndExpenses < ActiveRecord::Migration[7.2]
  def change
    # Aggiungi status ai rimborsi
    add_column :reimboursements, :status, :integer, default: 0, null: false
    
    # Aggiungi status alle spese
    add_column :expenses, :status, :integer, default: 0, null: false
    
    # Rimuovi la relazione con la tabella states
    remove_foreign_key :reimboursements, :states if foreign_key_exists?(:reimboursements, :states)
    remove_column :reimboursements, :state_id, :bigint if column_exists?(:reimboursements, :state_id)
  end
end
