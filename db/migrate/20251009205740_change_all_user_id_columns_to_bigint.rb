class ChangeAllUserIdColumnsToBigint < ActiveRecord::Migration[7.2]
  def up
    # Mappa di tabelle e le loro colonne foreign key che potrebbero essere integer
    foreign_key_columns = {
      bank_accounts: [ :user_id ],
      reimboursements: [ :user_id, :bank_account_id, :paypal_account_id ],
      notes: [ :user_id, :reimboursement_id ],
      vehicles: [ :user_id ],
      expenses: [ :reimboursement_id, :project_id ],
      users: [ :role_id ]
    }

    foreign_key_columns.each do |table_name, columns|
      next unless table_exists?(table_name)

      columns.each do |column_name|
        next unless column_exists?(table_name, column_name)

        # Determina la tabella di riferimento
        reference_table = case column_name
        when :user_id then :users
        when :bank_account_id then :bank_accounts
        when :paypal_account_id then :paypal_accounts
        when :reimboursement_id then :reimboursements
        when :project_id then :projects
        when :role_id then :roles
        end

        # Rimuovi foreign key se esiste
        if reference_table && foreign_key_exists?(table_name, reference_table)
          remove_foreign_key table_name, reference_table
        end

        # Cambia il tipo della colonna a bigint
        change_column table_name, column_name, :bigint

        # Ricrea la foreign key
        if reference_table && table_exists?(reference_table)
          add_foreign_key table_name, reference_table
        end
      end
    end
  end

  def down
    # Rollback: torna a integer (attenzione: potrebbe causare perdita di dati)
    foreign_key_columns = {
      bank_accounts: [ :user_id ],
      reimboursements: [ :user_id, :bank_account_id, :paypal_account_id ],
      notes: [ :user_id, :reimboursement_id ],
      vehicles: [ :user_id ],
      expenses: [ :reimboursement_id, :project_id ],
      users: [ :role_id ]
    }

    foreign_key_columns.each do |table_name, columns|
      next unless table_exists?(table_name)

      columns.each do |column_name|
        next unless column_exists?(table_name, column_name)

        # Determina la tabella di riferimento
        reference_table = case column_name
        when :user_id then :users
        when :bank_account_id then :bank_accounts
        when :paypal_account_id then :paypal_accounts
        when :reimboursement_id then :reimboursements
        when :project_id then :projects
        when :role_id then :roles
        end

        # Rimuovi foreign key se esiste
        if reference_table && foreign_key_exists?(table_name, reference_table)
          remove_foreign_key table_name, reference_table
        end

        # Cambia il tipo della colonna a integer
        change_column table_name, column_name, :integer

        # Ricrea la foreign key
        if reference_table && table_exists?(reference_table)
          add_foreign_key table_name, reference_table
        end
      end
    end
  end
end
