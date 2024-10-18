class Note < ApplicationRecord
  belongs_to :state
  belongs_to :reimboursment
  belongs_to :user
end
