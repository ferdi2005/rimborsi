module ElectronicInvoiceProcessor
  extend ActiveSupport::Concern
  include ElectronicInvoiceHelper

  included do
    # Callback per convertire fatture elettroniche in PDF
    # Usiamo after_commit per assicurarci che il file sia completamente salvato
    # Evitiamo loop controllando che sia cambiato solo l'attachment principale
    after_commit :convert_and_attach_pdf, if: -> { should_generate_pdf? && !@generating_pdf }

    # Callback per popolare il supplier dalla fattura elettronica
    after_commit :populate_supplier_from_invoice, if: -> { should_populate_supplier? }
  end

  # Metodo per verificare se l'attachment è una fattura elettronica
  def electronic_invoice?
    return false unless attachment.attached?

    ElectronicInvoiceHelper.electronic_invoice?(attachment.content_type)
  end

  # Metodo per ottenere il PDF generato (se disponibile)
  def invoice_pdf
    pdf_attachment if pdf_attachment.attached?
  end

  # Metodo per verificare se è disponibile un PDF della fattura
  def has_invoice_pdf?
    pdf_attachment.attached?
  end

  # Determina se il PDF deve essere generato o rigenerato
  def should_generate_pdf?
    return false unless electronic_invoice? && attachment.attached?
    return false if @generating_pdf # Evita loop durante la generazione

    # Genera il PDF se:
    # 1. Non esiste ancora un PDF
    # 2. L'attachment principale è stato modificato (non il PDF)
    !has_invoice_pdf? || main_attachment_changed?
  end

  # Verifica se l'attachment principale (fattura) è stato modificato
  def main_attachment_changed?
    return false unless attachment.attached?

    # Controlla solo se è cambiato l'attachment della fattura elettronica
    # Non considera i cambiamenti del PDF allegato
    saved_change_to_attribute?(:attachment) ||
    (previous_changes.key?("attachment") && electronic_invoice?)
  end

  # Rigenera il PDF della fattura elettronica (utile per aggiornamenti manuali)
  def regenerate_invoice_pdf!
    return false unless electronic_invoice?

    # Rimuovi il PDF esistente se presente
    pdf_attachment.purge if has_invoice_pdf?

    # Genera il nuovo PDF
    convert_and_attach_pdf

    true
  rescue => e
    Rails.logger.error "Errore durante la rigenerazione del PDF: #{e.message}"
    false
  end

  # Determina se il supplier deve essere popolato dalla fattura elettronica
  def should_populate_supplier?
    return false unless electronic_invoice? && attachment.attached?
    return false if @populating_supplier # Evita loop durante il popolamento

    # Popola il supplier se:
    # 1. È una fattura elettronica
    # 2. Il campo supplier è vuoto o l'attachment è stato modificato
    # 3. Non è una spesa auto (che non richiede il supplier)
    !car? && (supplier.blank? || main_attachment_changed?)
  end

  # Estrae i dati della fattura elettronica
  def extract_invoice_data
    return {} unless electronic_invoice? && attachment.attached?

    begin
      # Leggi il contenuto del file
      file_content = attachment.download

      # Se è un file P7M, decrittalo prima
      xml_content = if ElectronicInvoiceHelper.is_p7m_file?(attachment.content_type)
        ElectronicInvoiceHelper.decrypt_p7m(file_content)
      else
        file_content
      end

      # Parse dell'XML per estrarre i dati
      ElectronicInvoiceHelper.parse_xml(xml_content)
    rescue => e
      Rails.logger.error "Errore durante l'estrazione dei dati della fattura elettronica: #{e.message}"
      {}
    end
  end

  # Metodi di classe per operazioni batch
  module ClassMethods
    # Rigenera i PDF per tutte le fatture elettroniche
    def regenerate_all_invoice_pdfs
      electronic_invoices = joins(:attachment_attachment).where.not(attachment_attachment: nil).select(&:electronic_invoice?)

      success_count = 0
      error_count = 0

      electronic_invoices.each do |expense|
        if expense.regenerate_invoice_pdf!
          success_count += 1
        else
          error_count += 1
        end
      end

      Rails.logger.info "Rigenerazione PDF completata: #{success_count} successi, #{error_count} errori"
      { success: success_count, errors: error_count }
    end

    # Trova tutte le fatture elettroniche senza PDF
    def electronic_invoices_without_pdf
      joins(:attachment).where.not(attachment: nil).select do |expense|
        expense.electronic_invoice? && !expense.has_invoice_pdf?
      end
    end
  end

  private

  # Callback per popolare il supplier dalla fattura elettronica
  def populate_supplier_from_invoice
    return unless electronic_invoice? && attachment.attached?
    return if @populating_supplier # Evita loop di popolamento
    return if car? # Le spese auto non richiedono il supplier

    begin
      Rails.logger.info "Fattura elettronica processata correttamente"
    rescue => e
      Rails.logger.error "Errore durante il popolamento automatico del supplier: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
    ensure
      # Rimuovi il flag anche in caso di errore
      @populating_supplier = false
    end
  end

  # Callback per convertire e allegare il PDF
  def convert_and_attach_pdf
    return unless electronic_invoice?
    return if @generating_pdf # Evita loop di generazione

    begin
      # Imposta il flag per evitare loop
      @generating_pdf = true

      # Se esiste già un PDF e l'attachment è cambiato, rimuovilo
      if has_invoice_pdf? && main_attachment_changed?
        Rails.logger.info "Rimuovo il PDF esistente per rigenerarlo con il nuovo attachment"
        pdf_attachment.purge
      end

      # Leggi il contenuto del file
      file_content = attachment.download

      # Genera il PDF utilizzando l'helper
      pdf_content = ElectronicInvoiceHelper.convert_to_pdf(file_content, attachment.content_type)

      # Crea il filename per il PDF
      original_filename = attachment.filename.to_s
      pdf_filename = ElectronicInvoiceHelper.generate_pdf_filename(original_filename)

      # Crea un file temporaneo per il PDF
      temp_file = Tempfile.new([ "invoice_pdf", ".pdf" ])
      temp_file.binmode
      temp_file.write(pdf_content)
      temp_file.rewind

      # Allega il PDF generato
      pdf_attachment.attach(
        io: temp_file,
        filename: pdf_filename,
        content_type: "application/pdf"
      )

      temp_file.close
      temp_file.unlink

      Rails.logger.info "PDF generato con successo per la fattura elettronica: #{pdf_filename}"
    rescue => e
      Rails.logger.error "Errore durante la conversione automatica della fattura elettronica: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
    ensure
      # Rimuovi il flag anche in caso di errore
      @generating_pdf = false
    end
  end
end
