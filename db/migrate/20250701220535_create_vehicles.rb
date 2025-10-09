class CreateVehicles < ActiveRecord::Migration[7.2]
  def change
    create_table :vehicles do |t|
      t.string :name
      t.integer :vehicle_category
      t.integer :fuel_type
      t.string :brand
      t.string :model
      t.boolean :default
      t.bigint :user_id, null: false

      t.timestamps
    end

    add_foreign_key :vehicles, :users
  end
end
