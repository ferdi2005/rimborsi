class Reimboursement < ApplicationRecord
  belongs_to :state
  belongs_to :user
  belongs_to :bank_account
  belongs_to :paypal_account
end
