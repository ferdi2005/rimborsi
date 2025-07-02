class Expense < ApplicationRecord
  belongs_to :reimboursement
  belongs_to :vehicle, optional: true
  belongs_to :project

  has_one_attached :attachment

  # Enumerativo per gli status
  enum :status, {
    created: 0,
    approved: 1,
    denied: 2
  }, prefix: true

  # Validazioni
  validates :amount, presence: true, unless: :car?
  validates :amount, numericality: { greater_than: 0 }, allow_blank: true
  validates :purpose, presence: true
  validates :date, presence: true
  validates :project, presence: true

  # Validation: attachment is required only if not car expense
  validates :attachment, presence: true, unless: :car?

  # Validazioni specifiche per spese auto
  validates :calculation_date, presence: true, if: :car?
  validates :departure, presence: true, if: :car?
  validates :arrival, presence: true, if: :car?
  validates :distance, presence: true, numericality: { greater_than: 0 }, if: :car?
  validates :vehicle, presence: true, if: :car?
  validates :quota_capitale, presence: true, numericality: { greater_than_or_equal_to: 0 }, if: :car?
  validates :carburante, presence: true, numericality: { greater_than_or_equal_to: 0 }, if: :car?
  validates :pneumatici, presence: true, numericality: { greater_than_or_equal_to: 0 }, if: :car?
  validates :manutenzione, presence: true, numericality: { greater_than_or_equal_to: 0 }, if: :car?


  # Callback per calcolare automaticamente l'importo per le spese auto
  before_save :calculate_auto_amount, if: :car?

  # Callback per aggiornare lo stato del rimborso quando una spesa viene approvata
  after_update :update_reimboursement_status, if: :saved_change_to_status?

  # Scopes
  scope :car_expenses, -> { where(car: true) }
  scope :non_car_expenses, -> { where(car: false) }
  scope :approved_expenses, -> { where(status: "approved") }
  scope :denied_expenses, -> { where(status: "denied") }

  private


  # Metodo per calcolare l'importo delle spese auto
  def calculate_auto_amount
    return unless car? && quota_capitale && carburante && pneumatici && manutenzione && distance

    # Somma delle quote
    cost_per_km = quota_capitale + carburante + pneumatici + manutenzione

    # Moltiplica per la distanza
    total_distance = distance

    # Se andata e ritorno, moltiplica per 2
    total_distance *= 2 if return_trip?

    # Calcola il totale e dividi sempre per 2
    calculated_amount = (cost_per_km * total_distance) / 2

    self.amount = calculated_amount.round(2)
  end

  # Metodi per la traduzione degli status
  def self.status_translations
    {
      "created" => "Creata",
      "approved" => "Approvata",
      "denied" => "Negata"
    }
  end

  def status_in_italian
    self.class.status_translations[status] || status.humanize
  end

  private

  # Aggiorna lo stato del rimborso quando una spesa viene approvata
  def update_reimboursement_status
    return unless status_approved? && reimboursement

    # Se questa è la prima spesa approvata e il rimborso è ancora in "created",
    # passa il rimborso a "in_process"
    if reimboursement.status_created? && reimboursement.expenses.status_approved.count == 1
      reimboursement.update!(status: "in_process")
    end
  end
end
