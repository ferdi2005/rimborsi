class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Callbacks per prevenire eliminazione se ci sono rimborsi
  before_destroy :check_associated_reimboursements

  # Associations
  belongs_to :role, optional: true
  has_many :bank_accounts, dependent: :destroy
  has_many :paypal_accounts, dependent: :destroy
  has_many :vehicles, dependent: :destroy
  has_many :reimboursements, dependent: :destroy
  has_many :notes, dependent: :destroy
  has_many :expenses, through: :reimboursements

  # Validations
  validates :name, presence: true, length: { minimum: 2, maximum: 50 }
  validates :surname, presence: true, length: { minimum: 2, maximum: 50 }
  validates :username, presence: true, uniqueness: true, length: { minimum: 3, maximum: 30 },
            format: { with: /\A[a-zA-Z0-9_]+\z/, message: "può contenere solo lettere, numeri e underscore" }

  # Validazione telefono italiano (opzionale ma se presente deve essere valido, senza spazi)
  validates :telephone, format: {
    with: /\A(\+39)?[0-9]{6,13}\z/,
    message: "deve essere un numero di telefono italiano valido senza spazi"
  }, allow_blank: true

  # Validazione email più rigorosa
  validates :email, format: {
    with: /\A[a-zA-Z0-9.!#$%&'*+\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*\z/,
    message: "deve essere un indirizzo email valido"
  }

  # Metodi per gestire il conto predefinito
  def default_account
    default_bank_account || default_paypal_account
  end

  def default_bank_account
    bank_accounts.find_by(default: true)
  end

  def default_paypal_account
    paypal_accounts.find_by(default: true)
  end

  def default_vehicle
    vehicles.find_by(default: true)
  end

  def has_default_account?
    default_account.present?
  end

  # Metodo per verificare se l'utente può essere eliminato
  def can_be_deleted?
    reimboursements.count == 0
  end

  # Metodo per disattivare/attivare l'utente
  def deactivate!
    update!(active: false)
  end

  def activate!
    update!(active: true)
  end

  # Override del metodo devise per controllare se l'account è attivo
  def active_for_authentication?
    super && active?
  end

  # Messaggio per account disattivato
  def inactive_message
    active? ? super : :account_inactive
  end

  private

  def check_associated_reimboursements
    if reimboursements.any?
      errors.add(:base, "Impossibile eliminare l'utente: ha dei rimborsi associati")
      throw(:abort)
    end
  end
end
