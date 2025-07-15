class RemoveSupplierFromExpenses < ActiveRecord::Migration[7.2]
  def change
    remove_column :expenses, :supplier, :string
  end
end
