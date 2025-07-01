class Reimboursement < ApplicationRecord
  belongs_to :user
  belongs_to :bank_account, optional: true
  belongs_to :paypal_account, optional: true
  has_many :expenses, dependent: :destroy
  has_many :notes, dependent: :destroy

  # Enumerativo per gli status
  enum :status, {
    created: 0,
    in_process: 1,
    approved: 2,
    paid: 3,
    waiting: 4
  }, prefix: true

  # Validazioni
  validate :must_have_payment_method
  validate :must_have_expenses

  # Nested attributes per le spese
  accepts_nested_attributes_for :expenses, reject_if: :all_blank, allow_destroy: true

  # Callbacks
  after_update :send_status_change_notification, if: :saved_change_to_status?

  # Metodi per la traduzione degli status
  def self.status_translations
    {
      "created" => "Creato",
      "in_process" => "In Elaborazione",
      "approved" => "Approvato",
      "paid" => "Pagato",
      "waiting" => "In Attesa"
    }
  end

  def status_in_italian
    self.class.status_translations[status] || status.humanize
  end

  # Metodo per verificare se il rimborso può essere approvato
  def can_be_approved?
    # Tutte le spese devono essere approvate o negate (non in created)
    # e deve esserci almeno una spesa approvata
    expenses.any? && expenses.all? { |expense| expense.status != "created" } && expenses.any? { |expense| expense.status == "approved" }
  end

  # Metodi di utilità
  def payment_method
    return bank_account if bank_account.present?
    return paypal_account if paypal_account.present?
    nil
  end

  def payment_method_type
    return "Conto Bancario" if bank_account.present?
    return "PayPal" if paypal_account.present?
    "Nessuno"
  end

  # Calcola il totale escludendo le spese negate
  def total_amount
    expenses.where.not(status: "denied").sum(:amount) || 0
  end

  # Calcola il totale di tutte le spese (incluse quelle negate)
  def gross_total_amount
    expenses.sum(:amount) || 0
  end

  # Calcola il totale delle spese negate
  def denied_amount
    expenses.where(status: "denied").sum(:amount) || 0
  end

  private

  def send_status_change_notification
    ReimboursementMailer.status_changed(self).deliver_later
  end

  def must_have_payment_method
    if bank_account.blank? && paypal_account.blank?
      errors.add(:base, "Deve essere selezionato un metodo di pagamento (Conto Bancario o PayPal)")
    elsif bank_account.present? && paypal_account.present?
      errors.add(:base, "Può essere selezionato solo un metodo di pagamento")
    end
  end

  def must_have_expenses
    if expenses.empty? || expenses.all? { |expense| expense.marked_for_destruction? }
      errors.add(:base, "Deve avere almeno una spesa")
    end
  end
end
