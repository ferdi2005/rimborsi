class CreateNotes < ActiveRecord::Migration[7.2]
  def change
    create_table :notes do |t|
      t.references :reimboursement, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true, type: :bigint
      t.text :text

      t.timestamps
    end
  end
end
