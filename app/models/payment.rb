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
    require "builder"

    xml = ::Builder::XmlMarkup.new(indent: 4)
    xml.instruct!

    xml.GrpHdr do |grp|
      grp.MsgId id
      grp.CreDtTm DateTime.now.iso8601
      grp.NbOfTxs reimboursements.count
      grp.CtrlSum sprintf("%.2f", total)
      grp.InitgPty do |init|
        init.Id do |id_tag|
          id_tag.OrgId do |org|
            org.Othr do |othr|
              othr.Id "BGCJC"
              othr.Issr "CBI"
            end
          end
        end
      end
    end

    xml.PmtInf do |pmt|
      pmt.PmtInfId id
      pmt.PmtMtd "TRF"
      pmt.PmtTpInf do |pmt_tp|
        pmt_tp.InstrPrty "NORM"
      end
      pmt.SvcLvl do |svc|
        svc.Cd "SEPA"
      end
      pmt.ReqdExctnDt do |req_dt|
        req_dt.Dt next_business_day.strftime("%Y-%m-%d")
      end
      pmt.Dbtr do |dbtr|
        dbtr.Nm "Wikimedia Italia - Associazione per la diffusione della conoscenza libera - APS-ETS"
      end
      pmt.DbtrAcct do |dbtr_acct|
        dbtr_acct.Id do |id_tag|
          id_tag.IBAN "IT08F0306909606100000145960"
        end
      end
      pmt.DbtrAgt do |dbtr_agt|
        dbtr_agt.FinInstnId do |fin|
          fin.ClrSysMmbId do |clr|
            clr.MmbId "03069"
          end
        end
      end

      reimboursements.includes(:bank_account, :user).each do |reimbursement|
      xml.CdtTrfTxInf do |cdt|
        cdt.PmtId do |pmt_id|
          pmt_id.InstrId reimbursement.id
          pmt_id.EndToEndId "rimborso#{reimbursement.id}"
        end
        cdt.CtgyPurp do |ctgy|
          ctgy.Prtry "Rimborso spese n. #{reimbursement.id}"
        end
        cdt.Amt do |amt|
          amt.InstdAmt "EUR#{sprintf('%.2f', reimbursement.total_amount)}"
        end
        cdt.Cdtr do |cdtr|
          cdtr.Nm reimbursement.bank_account.owner
        end
        cdt.CdtrAcct do |cdtr_acct|
          cdtr_acct.Id do |id_tag|
            id_tag.IBAN reimbursement.bank_account.iban
          end
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
    when "paid"
      reimboursements.update_all(status: :paid)
      # Avvia il job per processare il pagamento solo se è appena stato marcato come pagato
      ProcessPaymentJob.perform_later(id) if saved_change_to_status? && status_paid?
    when "created"
      reimboursements.update_all(status: :approved)
    end
  end

  # Calcola il prossimo giorno lavorativo (lunedì-venerdì)
  def next_business_day
    date = Date.current + 1.day
    while date.saturday? || date.sunday?
      date += 1.day
    end
    date
  end
end
