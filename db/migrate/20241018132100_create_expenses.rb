class CreateExpenses < ActiveRecord::Migration[7.2]
  def change
    create_table :expenses do |t|
      t.bigint :reimboursement_id, null: false
      t.text :purpose
      t.date :date
      t.decimal :amount
      t.boolean :car
      t.date :calculation_date
      t.string :departure
      t.string :arrival
      t.integer :distance
      t.boolean :return_trip
      t.string :brand
      t.string :model
      t.decimal :quota_capitale
      t.decimal :carburante
      t.decimal :pneumatici
      t.decimal :manutenzione
      t.bigint :project_id, null: true

      t.timestamps
    end
    
    add_foreign_key :expenses, :reimboursements
    add_foreign_key :expenses, :projects
  end
end
