class Expense < ApplicationRecord
  belongs_to :reimboursment
  belongs_to :veichle_category
  belongs_to :fuel
  belongs_to :project
end
