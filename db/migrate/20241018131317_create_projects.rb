class CreateProjects < ActiveRecord::Migration[7.2]
  def change
    create_table :projects do |t|
      t.string :name
      t.decimal :budget
      t.boolean :active

      t.timestamps
    end
  end
end
