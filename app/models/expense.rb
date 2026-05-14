class Expense < ApplicationRecord
  belongs_to :reimboursement
  belongs_to :vehicle, optional: true
  belongs_to :fund, optional: true

  has_many_attached :attachments
  has_one_attached :pdf_attachment

  # Include il concern per la gestione delle fatture elettroniche
  include ElectronicInvoiceProcessor

  MAX_ATTACHMENTS = 10

  # Enumerativo per gli status
  enum :status, {
    created: 0,
    approved: 1,
    denied: 2
  }, prefix: true

  # Validazioni
  validates :amount, presence: true, unless: :car?
  validates :amount, numericality: { greater_than: 0 }, allow_blank: true
  validates :requested_amount, presence: true, numericality: { greater_than: 0 }
  validates :purpose, presence: true
  validates :date, presence: true
  validates :project, presence: true, length: { maximum: 255 }
  validates :fund, presence: true

  # Validation: attachments are required only if not car expense
  validates :attachments, presence: true, unless: :car?

  # Validazione del formato degli allegati
  validate :validate_attachment_format, if: -> { attachments.attached? }
  validate :validate_attachments_count, if: -> { attachments.attached? }
  validate :validate_single_electronic_invoice, if: -> { attachments.attached? }
  
  # Validazione che il requested_amount non superi l'amount
  validate :validate_requested_amount_not_exceeding_amount

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
  
  # Callback per impostare requested_amount uguale ad amount se non specificato
  before_validation :set_default_requested_amount

  # Callback per aggiornare lo stato del rimborso quando una spesa viene approvata
  after_update :update_reimboursement_status, if: :saved_change_to_status?
  
  # Callback per controllare file duplicati dopo la creazione
  after_create :check_for_duplicate_attachments

  # Scopes
  scope :car_expenses, -> { where(car: true) }
  scope :non_car_expenses, -> { where(car: false) }
  scope :approved_expenses, -> { where(status: "approved") }
  scope :denied_expenses, -> { where(status: "denied") }

  # Metodi per la traduzione degli status
  def self.status_translations
    {
      "created" => "In attesa di approvazione",
      "approved" => "Approvata",
      "denied" => "Negata"
    }
  end

  def status_in_italian
    self.class.status_translations[status] || status.humanize
  end

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
    
    # Se requested_amount non è stato ancora impostato o è uguale al vecchio amount, aggiornalo
    if requested_amount.blank? || requested_amount == amount_was
      self.requested_amount = self.amount
    end
  end

  # Imposta requested_amount uguale ad amount se non specificato
  def set_default_requested_amount
    if requested_amount.blank? && amount.present?
      self.requested_amount = amount
    end
  end

  # Validazione che il requested_amount non superi l'amount
  def validate_requested_amount_not_exceeding_amount
    return unless amount.present? && requested_amount.present?
    
    if requested_amount > amount
      errors.add(:requested_amount, "(€#{requested_amount}) non può essere maggiore dell'importo della spesa (€#{amount})")
    end
  end

  # Validazione del formato degli allegati
  def validate_attachment_format
    return unless attachments.attached?

    # Tipi MIME consentiti
    allowed_content_types = [
      # Immagini
      'image/jpeg',
      'image/jpg',
      'image/png',
      'image/gif',
      'image/bmp',
      'image/tiff',
      'image/webp',
      # PDF
      'application/pdf',
      # XML
      'application/xml',
      'text/xml',
      # XML.P7M (firma digitale)
      'application/pkcs7-mime',
      'application/x-pkcs7-mime'
    ]

    # Estensioni consentite
    allowed_extensions = %w[.jpg .jpeg .png .gif .bmp .tiff .webp .pdf .xml .p7m]

    attachments.each do |attachment|
      content_type = attachment.content_type
      filename = attachment.filename.to_s.downcase
      file_extension = File.extname(filename)

      # Controllo del content type
      unless allowed_content_types.include?(content_type)
        errors.add(:attachments, "deve essere un'immagine, un PDF o un file XML. Formato ricevuto: #{content_type}")
        next
      end

      # Controllo dell'estensione del file
      unless allowed_extensions.include?(file_extension)
        errors.add(:attachments, "deve avere un'estensione valida: #{allowed_extensions.join(', ')}")
        next
      end

      # Controllo dimensione file (massimo 20MB)
      max_size = 20.megabytes
      if attachment.byte_size > max_size
        errors.add(:attachments, "non può essere più grande di #{max_size / 1.megabyte}MB")
      end

      # Controllo specifico per file .p7m
      if file_extension == '.p7m'
        # Verifica che il nome file contenga .xml.p7m
        unless filename.include?('.xml.p7m')
          errors.add(:attachments, "i file P7M devono avere estensione .xml.p7m")
        end
      end
    end
  end

  def validate_attachments_count
    return unless attachments.attached?

    if attachments.count > MAX_ATTACHMENTS
      errors.add(:attachments, "non può contenere più di #{MAX_ATTACHMENTS} file")
    end
  end

  def validate_single_electronic_invoice
    return unless attachments.attached?

    electronic_invoices = attachments.select do |attachment|
      ElectronicInvoiceHelper.electronic_invoice?(attachment.content_type)
    end

    if electronic_invoices.count > 1
      errors.add(:attachments, "può contenere una sola fattura elettronica (XML/P7M)")
    end
  end

  def p7m_attachment?(attachment)
    filename = attachment.filename.to_s.downcase
    filename.include?(".xml.p7m") ||
      ElectronicInvoiceHelper.electronic_invoice?(attachment.content_type)
  end

  # Aggiorna lo stato del rimborso quando una spesa viene approvata
  def update_reimboursement_status
    return unless status_approved? && reimboursement

    # Se questa è la prima spesa approvata e il rimborso è ancora in "created",
    # passa il rimborso a "in_process"
    if reimboursement.status_created? && reimboursement.expenses.status_approved.count == 1
      reimboursement.update!(status: "in_process")
    end
  end

  # Controlla se esistono file duplicati e crea una nota
  def check_for_duplicate_attachments
    return unless attachments.attached?
    return unless reimboursement
    
    attachments.each do |attachment|
      next unless attachment.blob.present?
      
      current_checksum = attachment.blob.checksum
      
      # Trova altre spese con lo stesso checksum nello stesso rimborso
      duplicate = reimboursement.expenses.where.not(id: id).find do |other_expense|
        other_expense.attachments.any? do |other_attachment|
          other_attachment.blob.present? && other_attachment.blob.checksum == current_checksum
        end
      end
      
      if duplicate
        errors.add(:attachments, "Il file '#{attachment.filename}' è già stato allegato ad un'altra spesa di questo rimborso")
      end
    end
  end
end
