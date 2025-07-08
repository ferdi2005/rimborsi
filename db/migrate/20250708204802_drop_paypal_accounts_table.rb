class DropPaypalAccountsTable < ActiveRecord::Migration[7.2]
  def change
    drop_table :paypal_accounts do |t|
      t.string :email, null: false
      t.boolean :default, default: false
      t.references :user, null: false, foreign_key: true
      t.timestamps
    end
  end
end
