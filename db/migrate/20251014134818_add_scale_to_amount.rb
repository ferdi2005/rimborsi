class AddScaleToAmount < ActiveRecord::Migration[7.2]
  def change
    change_column :expenses, :amount, :decimal, precision: 8, scale: 2
  end
end
