class AddRequestedAmountToExpenses < ActiveRecord::Migration[7.2]
  def change
    add_column :expenses, :requested_amount, :decimal, precision: 8, scale: 2
  end
end
