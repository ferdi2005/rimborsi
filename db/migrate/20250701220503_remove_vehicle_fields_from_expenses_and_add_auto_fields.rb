class RemoveVehicleFieldsFromExpensesAndAddAutoFields < ActiveRecord::Migration[7.2]
  def change
    # Rimuovi i campi veicolo esistenti se esistono
    remove_column :expenses, :veichle_category_id, :integer if column_exists?(:expenses, :veichle_category_id)
    remove_column :expenses, :brand, :string if column_exists?(:expenses, :brand)
    remove_column :expenses, :model, :string if column_exists?(:expenses, :model)
    remove_column :expenses, :fuel_id, :integer if column_exists?(:expenses, :fuel_id)

    # Aggiungi i nuovi campi per le spese auto solo se non esistono
    add_column :expenses, :calculation_date, :date unless column_exists?(:expenses, :calculation_date)
    add_column :expenses, :departure, :string unless column_exists?(:expenses, :departure)
    add_column :expenses, :arrival, :string unless column_exists?(:expenses, :arrival)
    add_column :expenses, :distance, :integer unless column_exists?(:expenses, :distance)
    add_column :expenses, :return_trip, :boolean, default: false unless column_exists?(:expenses, :return_trip)
    add_column :expenses, :vehicle_id, :integer unless column_exists?(:expenses, :vehicle_id)
    add_column :expenses, :quota_capitale, :decimal, precision: 8, scale: 4 unless column_exists?(:expenses, :quota_capitale)
    add_column :expenses, :carburante, :decimal, precision: 8, scale: 4 unless column_exists?(:expenses, :carburante)
    add_column :expenses, :pneumatici, :decimal, precision: 8, scale: 4 unless column_exists?(:expenses, :pneumatici)
    add_column :expenses, :manutenzione, :decimal, precision: 8, scale: 4 unless column_exists?(:expenses, :manutenzione)

    add_index :expenses, :vehicle_id unless index_exists?(:expenses, :vehicle_id)
  end
end
