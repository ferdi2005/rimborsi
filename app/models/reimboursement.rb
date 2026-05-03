class Reimboursement < ApplicationRecord
  include PdfGeneratable

  belongs_to :user
  # Reso optional a livello di association: la presenza è applicata da
  # must_have_payment_method, che salta per le bozze.
  belongs_to :bank_account, optional: true
  belongs_to :payment, optional: true
  has_many :expenses, dependent: :destroy
  has_many :notes, dependent: :destroy

  # Enumerativo per gli status
  enum :status, {
    created: 0,
    in_process: 1,
    approved: 2,
    paid: 3,
    waiting: 4,
    draft: 5
  }, prefix: true

  # Validazioni: le bozze possono essere salvate parzialmente (senza conto bancario / senza spese)
  validate :must_have_payment_method, unless: :status_draft?
  validate :must_have_expenses, unless: :status_draft?

  # Nested attributes per le spese
  accepts_nested_attributes_for :expenses, reject_if: :all_blank, allow_destroy: true

  # Scopes
  scope :approved_with_bank_account, -> { where(status: :approved).joins(:bank_account) }
  scope :payable, -> { approved_with_bank_account.where(payment: nil) }
  scope :unpaid, -> { where.not(status: :paid) }

  # Callbacks
  after_update :send_status_change_notification, if: :should_notify_status_change?

  # Metodi per la traduzione degli status
  def self.status_translations
    {
      "draft" => "Bozza",
      "created" => "In attesa di elaborazione",
      "in_process" => "In elaborazione",
      "approved" => "Approvato",
      "paid" => "Pagato",
      "waiting" => "In attesa dell'utente"
    }
  end

  def status_in_italian
    self.class.status_translations[status] || status.humanize
  end

  # Metodo per verificare se il rimborso può essere approvato
  def can_be_approved?
    # Tutte le spese devono essere approvate; le bozze non sono mai approvabili
    expenses.any? && expenses.all?(&:status_approved?) && !status.in?([ "approved", "paid", "draft" ])
  end

  # Metodi di utilità
  def payment_method
    bank_account
  end

  def payment_method_type
    return "conto bancario" if bank_account.present?
    "Nessuno"
  end

  # Calcola il totale escludendo le spese negate
  def total_amount
    expenses.where.not(status: "denied").sum(:requested_amount) || 0
  end

  # Calcola il totale di tutte le spese (incluse quelle negate)
  def gross_total_amount
    expenses.sum(:requested_amount) || 0
  end

  # Calcola il totale delle spese negate
  def denied_amount
    expenses.where(status: "denied").sum(:requested_amount) || 0
  end

  # Verifica se il rimborso può essere modificato dall'utente specificato
  def can_be_edited_by?(user)
    return true if user.admin?
    return false unless user == self.user
    # Gli utenti normali possono modificare bozze e rimborsi in stato "created" o "waiting"
    status.in?([ "draft", "created", "waiting" ])
  end

  private

  # Le transizioni che entrano o escono da "draft" sono iniziate dall'utente
  # (salva bozza / invia) e non devono produrre email di notifica.
  def should_notify_status_change?
    return false unless saved_change_to_status?
    before, after = saved_change_to_status
    draft_value = self.class.statuses["draft"]
    before != draft_value && after != draft_value &&
      before != "draft" && after != "draft"
  end

  def send_status_change_notification
    ReimboursementMailer.status_changed(self).deliver_later
  end

  def must_have_payment_method
    if bank_account.blank?
      errors.add(:base, "Deve essere selezionato un conto bancario")
    end
  end

  def must_have_expenses
    if expenses.empty? || expenses.all? { |expense| expense.marked_for_destruction? }
      errors.add(:base, "Deve avere almeno una spesa")
    end
  end
end
