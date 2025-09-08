class PopulateRequestedAmountForExistingExpenses < ActiveRecord::Migration[7.2]
  def up
    # Popola requested_amount con il valore di amount per tutte le spese esistenti
    Expense.where(requested_amount: nil).find_each do |expense|
      expense.update_column(:requested_amount, expense.amount)
    end
  end

  def down
    # Opzionalmente possiamo resettare requested_amount a nil
    Expense.update_all(requested_amount: nil)
  end
end
