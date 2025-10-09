class CreateReimboursements < ActiveRecord::Migration[7.2]
  def change
    create_table :reimboursements do |t|
      t.references :user, null: false, foreign_key: true, type: :bigint
      t.references :bank_account, null: false, foreign_key: true
      t.references :paypal_account, null: false, foreign_key: true

      t.timestamps
    end
  end
end
