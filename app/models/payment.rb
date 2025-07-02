class Payment < ApplicationRecord
  has_many :reimboursements, dependent: :nullify

  # Enumerativo per gli status
  enum :status, {
    created: 0,
    paid: 1
  }, prefix: true

  # Validazioni
  validate :payment_date_present_if_paid
  validate :reimboursements_have_bank_accounts

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :by_payment_date, -> { order(:payment_date) }

  # Callbacks
  before_save :calculate_total
  after_update :update_reimboursements_status, if: :saved_change_to_status?

  def to_s
    "Pagamento ##{id} - €#{total}"
  end

  def can_be_modified?
    status_created?
  end

  # Verifica se ci sono rimborsi che sono stati riportati a "created" dopo un errore di processing
  def has_failed_reimboursements?
    status_paid? && reimboursements.status_created.any?
  end

  # Conta i rimborsi che sono stati processati con successo
  def successfully_processed_count
    return 0 unless status_paid?
    reimboursements.status_paid.count
  end

  # Conta i rimborsi che hanno fallito il processing
  def failed_processing_count
    return 0 unless status_paid?
    reimboursements.status_created.count
  end

  def mark_as_paid!(date = Date.current)
    transaction do
      update!(status: :paid, payment_date: date)
      reimboursements.update_all(status: :paid)
    end
    # Avvia il job per processare il pagamento (generazione PDF e upload)
    ProcessPaymentJob.perform_later(id)
  end

  def revert_to_created!
    transaction do
      update!(status: :created, payment_date: nil)
      reimboursements.update_all(status: :approved)
    end
  end

  # Metodi per la traduzione degli status
  def self.status_translations
    {
      "created" => "Creato",
      "paid" => "Pagato"
    }
  end

  def status_in_italian
    self.class.status_translations[status] || status.humanize
  end

  # Genera XML per il flusso di pagamento
  def generate_xml_flow
    require 'builder'

    xml = ::Builder::XmlMarkup.new(indent: 2)
    xml.instruct!

    xml.PaymentFlow do |flow|
      flow.PaymentId id
      flow.PaymentDate payment_date&.strftime("%Y-%m-%d")
      flow.TotalAmount total
      flow.Status status_in_italian
      flow.CreatedAt created_at.strftime("%Y-%m-%d %H:%M:%S")

      flow.Reimboursements do |reimbursements_xml|
        reimboursements.includes(:bank_account, :user).each do |reimbursement|
          reimbursements_xml.Reimboursement do |r|
            r.Id reimbursement.id
            r.UserId reimbursement.user.id
            r.UserName "#{reimbursement.user.name} #{reimbursement.user.surname}"
            r.IBAN reimbursement.bank_account&.iban
            r.BankName reimbursement.bank_account&.bank_name
            r.Amount reimbursement.total_amount
            r.Status reimbursement.status_in_italian
            r.CreatedAt reimbursement.created_at.strftime("%Y-%m-%d %H:%M:%S")
          end
        end
      end
    end

    xml.target!
  end

  # Ricalcola e salva il totale del pagamento
  def recalculate_total!
    calculate_total
    save!
  end

  private

  def calculate_total
    self.total = reimboursements.sum(&:total_amount)
  end

  def payment_date_present_if_paid
    if status_paid? && payment_date.blank?
      errors.add(:payment_date, "deve essere presente per i pagamenti eseguiti")
    end
  end

  def reimboursements_have_bank_accounts
    if reimboursements.any? { |r| r.bank_account.blank? }
      errors.add(:reimboursements, "devono tutti avere un conto bancario associato")
    end
  end

  def update_reimboursements_status
    case status
    when 'paid'
      reimboursements.update_all(status: :paid)
      # Avvia il job per processare il pagamento solo se è appena stato marcato come pagato
      ProcessPaymentJob.perform_later(id) if saved_change_to_status? && status_paid?
    when 'created'
      reimboursements.update_all(status: :approved)
    end
  end
end
