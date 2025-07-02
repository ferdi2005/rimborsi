class AddPaymentToReimboursements < ActiveRecord::Migration[7.2]
  def change
    add_reference :reimboursements, :payment, null: true, foreign_key: true
  end
end
