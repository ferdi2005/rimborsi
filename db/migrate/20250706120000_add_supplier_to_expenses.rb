class AddSupplierToExpenses < ActiveRecord::Migration[7.2]
  def change
    add_column :expenses, :supplier, :string
  end
end
