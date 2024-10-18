class CreateFuels < ActiveRecord::Migration[7.2]
  def change
    create_table :fuels do |t|
      t.string :label

      t.timestamps
    end
  end
end
