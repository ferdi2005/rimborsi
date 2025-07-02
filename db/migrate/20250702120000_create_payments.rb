class CreatePayments < ActiveRecord::Migration[7.2]
  def change
    create_table :payments do |t|
      t.date :payment_date
      t.decimal :total, precision: 8, scale: 2
      t.integer :status, default: 0, null: false

      t.timestamps
    end

    add_index :payments, :status
    add_index :payments, :payment_date
  end
end
