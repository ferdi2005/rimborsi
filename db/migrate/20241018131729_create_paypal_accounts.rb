class CreatePaypalAccounts < ActiveRecord::Migration[7.2]
  def change
    create_table :paypal_accounts do |t|
      t.string :email
      t.references :user, null: false, foreign_key: true
      t.boolean :default

      t.timestamps
    end
  end
end
