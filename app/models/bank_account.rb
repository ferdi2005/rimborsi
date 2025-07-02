class BankAccount < ApplicationRecord
  belongs_to :user

  # Validazioni
  validates :iban, presence: true
  validates :owner, presence: true, length: { minimum: 2, maximum: 100 }
  validates :bank_name, presence: true, length: { minimum: 2, maximum: 100 }, allow_blank: true

  # Callback per normalizzare l'IBAN
  before_validation :normalize_iban

  # Validazione custom per IBAN usando iban-tools
  validate :validate_iban_format

  # Callback per gestire un solo conto predefinito per utente
  before_save :ensure_single_default_account

  private

  def normalize_iban
    return unless iban.present?

    # Rimuovi spazi e converti in maiuscolo
    self.iban = iban.gsub(/\s+/, '').upcase
  end

  def validate_iban_format
    return unless iban.present?

    begin
      # Usa iban-tools per validare l'IBAN
      unless IBANTools::IBAN.valid?(iban)
        errors.add(:iban, "non è un IBAN valido")
        return
      end

    rescue StandardError => e
      errors.add(:iban, "formato non valido")
    end
  end

  def ensure_single_default_account
    return unless default? && default_changed?

    # Rimuovi il flag predefinito da tutti gli altri conti bancari dell'utente
    user.bank_accounts.where.not(id: id).update_all(default: false)

    # Rimuovi il flag predefinito da tutti gli account PayPal dell'utente
    user.paypal_accounts.update_all(default: false)
  end
end
