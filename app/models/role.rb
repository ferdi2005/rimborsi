class Role < ApplicationRecord
  has_many :users, dependent: :nullify
end
