class ChangeAllUserIdColumnsToBigint < ActiveRecord::Migration[7.2]
  def up
    # Lista di tabelle che potrebbero avere user_id come integer
    tables_with_user_id = [ :bank_accounts, :reimboursements, :notes, :vehicles ]

    tables_with_user_id.each do |table_name|
      if table_exists?(table_name) && column_exists?(table_name, :user_id)
        # Rimuovi foreign key se esiste
        if foreign_key_exists?(table_name, :users)
          remove_foreign_key table_name, :users
        end

        # Cambia il tipo della colonna a bigint
        change_column table_name, :user_id, :bigint

        # Ricrea la foreign key
        add_foreign_key table_name, :users
      end
    end
  end

  def down
    # Rollback: torna a integer (attenzione: potrebbe causare perdita di dati)
    tables_with_user_id = [ :bank_accounts, :reimboursements, :notes, :vehicles ]

    tables_with_user_id.each do |table_name|
      if table_exists?(table_name) && column_exists?(table_name, :user_id)
        # Rimuovi foreign key
        if foreign_key_exists?(table_name, :users)
          remove_foreign_key table_name, :users
        end

        # Cambia il tipo della colonna a integer
        change_column table_name, :user_id, :integer

        # Ricrea la foreign key
        add_foreign_key table_name, :users
      end
    end
  end
end
