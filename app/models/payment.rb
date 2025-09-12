class Payment < ApplicationRecord
  has_many :reimboursements, dependent: :nullify

  # Enumerativo per gli status
  enum :status, {
    created: 0,
    paid: 1,
    error: 2
  }, prefix: true

  # Validazioni
  validate :payment_date_present_if_paid
  validate :reimboursements_have_bank_accounts

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :by_payment_date, -> { order(:payment_date) }

  # Callbacks
  before_save :calculate_total

  def to_s
    "Pagamento ##{id} - €#{total}"
  end

  def can_be_modified?
    status_created?
  end

  # Conta i rimborsi che sono stati processati con successo
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

  def mark_as_error!
    update!(status: :error)
  end

  def retry_processing!
    return unless status_error?

    # Mantieni lo stato paid e riavvia il job di processamento
    update!(status: :paid)
    ProcessPaymentJob.perform_later(id)
  end

  def can_be_retried?
    status_error?
  end

  # Metodi per la traduzione degli status
  def self.status_translations
    {
      "created" => "Creato",
      "paid" => "Pagato",
      "error" => "Errore"
    }
  end

  def status_in_italian
    self.class.status_translations[status] || status.humanize
  end

  # Genera XML per il flusso di pagamento
  def generate_xml_flow
    require "builder"

    xml = ::Builder::XmlMarkup.new(indent: 2)
    xml.instruct! :xml, version: "1.0", encoding: "utf-8"

    xml.CBIPaymentRequest("xmlns" => "urn:CBI:xsd:CBIPaymentRequest.00.03.09") do
      xml.GrpHdr do |grp|
        grp.MsgId "payment_#{id}"
        grp.CreDtTm DateTime.now.iso8601
        grp.NbOfTxs reimboursements.count
        grp.CtrlSum sprintf("%.2f", total)
        grp.InitgPty do |init|
          init.Id do |id_tag|
            id_tag.OrgId do |org|
              org.Othr do |othr|
                othr.Id ENV["COD_BANCA"]
                othr.Issr "CBI"
              end
            end
          end
        end
      end

      xml.PmtInf do |pmt|
        pmt.PmtInfId "payment_#{id}"
        pmt.PmtMtd "TRF"
        pmt.PmtTpInf do |pmt_tp|
          pmt_tp.SvcLvl do |svc|
            svc.Cd "SEPA"
          end
        end
        pmt.ReqdExctnDt next_business_day.strftime("%Y-%m-%d")

        pmt.Dbtr do |dbtr|
          dbtr.Nm "Wikimedia Italia - Associazione per la diffusione della conoscenza libera - APS-ETS"
        end

        pmt.DbtrAcct do |dbtr_acct|
          dbtr_acct.Id do |id_tag|
            id_tag.IBAN ENV["IBAN"]
          end
        end

        pmt.DbtrAgt do |dbtr_agt|
          dbtr_agt.FinInstnId do |fin|
            fin.ClrSysMmbId do |clr|
              clr.MmbId "03069" # Codice ABI Intesa San Paolo
            end
          end
        end

        reimboursements.includes(:bank_account, :user).each do |reimbursement|
          xml.CdtTrfTxInf do |cdt|
            cdt.PmtId do |pmt_id|
              pmt_id.InstrId reimbursement.id.to_s
              pmt_id.EndToEndId "rimborso#{reimbursement.id}"
            end

            cdt.PmtTpInf do |pmt_tp|
              pmt_tp.CtgyPurp do |ctgy|
                ctgy.Cd "SUPP" # Codice per pagamenti fornitori/rimborsi
              end
            end

            cdt.Amt do |amt|
              amt.InstdAmt sprintf("%.2f", reimbursement.total_amount), "Ccy" => "EUR"
            end

            cdt.Cdtr do |cdtr|
              cdtr.Nm reimbursement.bank_account.owner
            end

            cdt.CdtrAcct do |cdtr_acct|
              cdtr_acct.Id do |id_tag|
                id_tag.IBAN reimbursement.bank_account.iban
              end
            end

            # Aggiungi BIC/SWIFT se disponibile per il beneficiario
            if reimbursement.bank_account.bic_swift.present?
              cdt.CdtrAgt do |cdtr_agt|
                cdtr_agt.FinInstnId do |fin|
                  fin.BIC reimbursement.bank_account.bic_swift
                end
              end
            end

            # Informazioni di rimessa
            cdt.RmtInf do |rmt|
              rmt.Ustrd "Rimborso spese n. #{reimbursement.id}"
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

  # Calcola il prossimo giorno lavorativo (lunedì-venerdì)
  def next_business_day
    date = Date.current + 1.day
    while date.saturday? || date.sunday?
      date += 1.day
    end
    date
  end
end
