class CreateVeichleCategories < ActiveRecord::Migration[7.2]
  def change
    create_table :veichle_categories do |t|
      t.string :label

      t.timestamps
    end
  end
end
