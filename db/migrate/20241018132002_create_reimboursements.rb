class CreateReimboursements < ActiveRecord::Migration[7.2]
  def change
    create_table :reimboursements do |t|
      t.bigint :user_id, null: false
      t.references :bank_account, null: false, foreign_key: true
      t.references :paypal_account, null: false, foreign_key: true

      t.timestamps
    end

    add_foreign_key :reimboursements, :users
  end
end
