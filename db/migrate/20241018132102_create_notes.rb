class CreateNotes < ActiveRecord::Migration[7.2]
  def change
    create_table :notes do |t|
      t.references :reimboursement, null: false, foreign_key: true
      t.bigint :user_id, null: false
      t.text :text

      t.timestamps
    end

    add_foreign_key :notes, :users
  end
end
