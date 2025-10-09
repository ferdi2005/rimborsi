class CreateNotes < ActiveRecord::Migration[7.2]
  def change
    create_table :notes do |t|
      t.bigint :reimboursement_id, null: false
      t.bigint :user_id, null: false
      t.text :text

      t.timestamps
    end

    add_foreign_key :notes, :users
    add_foreign_key :notes, :reimboursements
  end
end
