class BankAccount < ApplicationRecord
  belongs_to :user

  # Validazioni
  validates :iban, presence: true
  validates :owner, presence: true, length: { minimum: 2, maximum: 100 }
  validates :bank_name, presence: true, length: { minimum: 2, maximum: 100 }, allow_blank: true
  validates :bic_swift, length: { minimum: 8, maximum: 11 }, allow_blank: true, format: { with: /\A[A-Z]{6}[A-Z0-9]{2}([A-Z0-9]{3})?\z/, message: "deve essere un codice BIC/SWIFT valido" }

  # Callback per normalizzare l'IBAN e BIC/SWIFT
  before_validation :normalize_iban_and_bic

  # Validazione custom per IBAN usando iban-tools
  validate :validate_iban_format

  # Validazione custom per BIC/SWIFT obbligatorio per conti non italiani
  validate :validate_bic_swift_for_non_italian_accounts

  # Callback per gestire un solo conto predefinito per utente
  before_save :ensure_single_default_account

  private

  def normalize_iban_and_bic
    if iban.present?
      # Rimuovi spazi e converti in maiuscolo per IBAN
      self.iban = iban.gsub(/\s+/, "").upcase
    end

    if bic_swift.present?
      # Rimuovi spazi e converti in maiuscolo per BIC/SWIFT
      self.bic_swift = bic_swift.gsub(/\s+/, "").upcase
    end
  end

  def validate_iban_format
    return unless iban.present?

    begin
      # Usa iban-tools per validare l'IBAN
      unless IBANTools::IBAN.valid?(iban)
        errors.add(:iban, "non è un IBAN valido")
        nil
      end

    rescue StandardError
      errors.add(:iban, "formato non valido")
    end
  end

  def validate_bic_swift_for_non_italian_accounts
    return unless iban.present?

    # Estrae il codice paese dall'IBAN (primi due caratteri)
    country_code = iban[0..1]

    # Se il conto non è italiano (IT) e non ha BIC/SWIFT, aggiungi errore
    if country_code != "IT" && bic_swift.blank?
      errors.add(:bic_swift, "è obbligatorio per conti bancari non italiani")
    end
  end

  def ensure_single_default_account
    return unless default? && default_changed?

    # Rimuovi il flag predefinito da tutti gli altri conti bancari dell'utente
    user.bank_accounts.where.not(id: id).update_all(default: false)
  end
end
