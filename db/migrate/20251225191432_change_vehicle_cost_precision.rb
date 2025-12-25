class ChangeVehicleCostPrecision < ActiveRecord::Migration[7.2]
  def change
    change_column :expenses, :quota_capitale, :decimal, precision: 10, scale: 4
    change_column :expenses, :carburante, :decimal, precision: 10, scale: 4
    change_column :expenses, :pneumatici, :decimal, precision: 10, scale: 4
    change_column :expenses, :manutenzione, :decimal, precision: 10, scale: 4
  end
end
