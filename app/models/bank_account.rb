class BankAccount < ApplicationRecord
  belongs_to :user
  
  # Validazioni
  validates :iban, presence: true
  validates :owner, presence: true
  
  # Callback per gestire un solo conto predefinito per utente
  before_save :ensure_single_default_account
  
  private
  
  def ensure_single_default_account
    return unless default? && default_changed?
    
    # Rimuovi il flag predefinito da tutti gli altri conti bancari dell'utente
    user.bank_accounts.where.not(id: id).update_all(default: false)
    
    # Rimuovi il flag predefinito da tutti gli account PayPal dell'utente
    user.paypal_accounts.update_all(default: false)
  end
end
