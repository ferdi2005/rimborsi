class AddDefaultToCarInExpenses < ActiveRecord::Migration[7.2]
  def change
    change_column_default :expenses, :car, false
  end
end
