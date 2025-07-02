class CreateExpenses < ActiveRecord::Migration[7.2]
  def change
    create_table :expenses do |t|
      t.references :reimboursement, null: false, foreign_key: true
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
      t.references :project, null: true, foreign_key: true

      t.timestamps
    end
  end
end
