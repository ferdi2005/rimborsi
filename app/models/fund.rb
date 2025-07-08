class Fund < ApplicationRecord
  has_many :expenses, dependent: :nullify

  validates :name, presence: true, uniqueness: true
  validates :budget, presence: true, numericality: { greater_than: 0 }

  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }

  def to_s
    name
  end

  def total_expenses
    expenses.sum(:amount) || 0
  end

  def remaining_budget
    budget - total_expenses
  end

  def budget_percentage_used
    return 0 if budget.zero?
    (total_expenses / budget * 100).round(2)
  end

  def over_budget?
    total_expenses > budget
  end
end
