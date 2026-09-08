class Reimboursement < ApplicationRecord
  include PdfGeneratable

  belongs_to :user
  belongs_to :bank_account, optional: true
  belongs_to :payment, optional: true
  belongs_to :fund, optional: true
  has_many :expenses, dependent: :destroy
  has_many :notes, dependent: :destroy

  validates :project, presence: true, length: { maximum: 255 }, unless: :status_draft?
  validates :fund, presence: true, if: -> { !status_draft? && (new_record? || status_was == "draft" || fund_id_was.present?) }
  validates :role, presence: true, unless: :status_draft?

  # Enumerativo per gli status
  enum :status, {
    created: 0,
    in_process: 1,
    approved: 2,
    paid: 3,
    waiting: 4,
    draft: 5
  }, prefix: true

  # Enumerativo per il ruolo del richiedente
  enum :role, {
    volunteer: "volontario",
    employee_collaborator: "dipendente",
    speaker_presenter: "relatore",
    scholarship_holder: "borsista",
    event_participant: "partecipante",
    event_co_organizer: "co_organizzatore",
    other: "altro"
  }, prefix: true

  # Validazioni
  validate :must_have_payment_method, unless: :status_draft?
  validate :must_have_expenses, unless: :status_draft?
  validate :must_have_valid_expenses, unless: :status_draft?
  validate :role_other_required_for_specific_roles, unless: :status_draft?
  validate :cannot_return_to_draft

  # Nested attributes per le spese
  accepts_nested_attributes_for :expenses, reject_if: :all_blank, allow_destroy: true

  # Scopes
  scope :approved_with_bank_account, -> { where(status: :approved).joins(:bank_account) }
  scope :payable, -> { approved_with_bank_account.where(payment: nil) }
  scope :unpaid, -> { where.not(status: :paid) }

  # Callbacks
  after_update :send_status_change_notification, if: :saved_change_to_status?
  after_save :sync_project_to_expenses, if: :saved_change_to_project?

  # Metodi per la traduzione degli status e ruoli
  def self.status_translations
    statuses.keys.each_with_object({}) do |st, h|
      h[st] = I18n.t("enums.reimboursement.status.#{st}", default: st.humanize)
    end
  end

  def self.role_translations
    roles.keys.each_with_object({}) do |r, h|
      h[r] = I18n.t("enums.reimboursement.role.#{r}", default: r.humanize)
    end
  end

  def status_name
    self.class.status_translations[status] || status.humanize
  end

  def display_role
    return I18n.t("reimboursements.role.not_specified", default: "Non specificato") if role.blank?

    base = self.class.role_translations[role] || role.to_s.humanize
    if role_other.present? && (role_event_co_organizer? || role_other?)
      "#{base} (#{role_other})"
    else
      base
    end
  end

  # Metodo per verificare se il rimborso può essere approvato
  def can_be_approved?
    return false if status_draft?

    # Tutte le spese devono essere approvate
    expenses.any? && expenses.all?(&:status_approved?) && status != "approved" && status != "paid"
  end

  # Metodi di utilità
  def payment_method
    bank_account
  end

  def payment_method_type
    if bank_account.present?
      I18n.t("rimborsi.payment_methods.bank", default: "conto bancario")
    else
      I18n.t("rimborsi.payment_methods.none", default: "nessuno")
    end
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
    # Gli utenti normali possono modificare i rimborsi in stato "draft", "created" o "waiting"
    status.in?([ "draft", "created", "waiting" ])
  end

  def display_fund_name
    return fund.name if fund.present?

    # Fallback per rimborsi storici con spese su fondi multipli o non ancora sincronizzati
    fund_names = expenses.map(&:fund).compact.map(&:name).uniq
    fund_names.any? ? fund_names.join(", ") : I18n.t("reimboursements.funds.not_assigned", default: "Non assegnato")
  end

  def single_fund?
    return true if fund.present?

    expenses.map(&:fund_id).compact.uniq.size <= 1
  end

  def display_project_name
    return project if project.present?

    # Fallback per rimborsi storici con spese su progetti multipli o non ancora sincronizzati
    project_names = expenses.map(&:project).compact.reject(&:blank?).uniq
    project_names.any? ? project_names.join(", ") : I18n.t("reimboursements.projects.not_assigned", default: "Non assegnato")
  end

  def single_project?
    distinct_projects = expenses.map(&:project).compact.reject(&:blank?).uniq
    return false if distinct_projects.size > 1

    true
  end

  def sync_project_to_expenses
    return if project.blank?

    if single_project?
      expenses.where(project: [nil, "", project_before_last_save]).update_all(project: project)
    else
      expenses.where(project: [nil, ""]).update_all(project: project)
    end
  end

  def causale_bonifico
    base_text = "Rimborso spese n. #{id} - #{display_fund_name} - #{display_project_name}"
    cleaned = base_text.gsub(/\s+/, " ").strip
    cleaned.truncate(140)
  end

  private

  def cannot_return_to_draft
    if persisted? && status_draft? && status_was.present? && status_was != "draft"
      errors.add(:status, :cannot_return_to_draft)
    end
  end

  def send_status_change_notification
    return if status_draft?

    ReimboursementMailer.status_changed(self).deliver_later
  end

  def must_have_payment_method
    if bank_account.blank?
      errors.add(:base, :missing_bank_account)
    end
  end

  def must_have_expenses
    if expenses.empty? || expenses.all? { |expense| expense.marked_for_destruction? }
      errors.add(:base, :missing_expenses)
    end
  end

  def must_have_valid_expenses
    expenses.each_with_index do |expense, idx|
      next if expense.marked_for_destruction?

      expense.reimboursement = self
      unless expense.valid?
        expense.errors.each do |err|
          msg = I18n.t("reimboursements.expenses.item_error",
                       index: idx + 1,
                       error: err.full_message,
                       default: "Spesa %{index}: %{error}")
          errors.add(:base, msg) unless errors[:base].include?(msg)
        end
      end
    end
  end

  def role_other_required_for_specific_roles
    return unless role_event_co_organizer? || role_other?

    if role_other.blank?
      errors.add(:role_other, :blank_for_selected_role)
    end
  end
end
