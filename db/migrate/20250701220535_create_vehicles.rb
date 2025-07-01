class CreateVehicles < ActiveRecord::Migration[7.2]
  def change
    create_table :vehicles do |t|
      t.string :name
      t.integer :vehicle_category
      t.integer :fuel_type
      t.string :brand
      t.string :model
      t.boolean :default
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
