require "hexapdf"
require "timeout"

module PdfGeneratable
  extend ActiveSupport::Concern
  include ActionView::Helpers::NumberHelper

  # Limiti di sicurezza per l'elaborazione dei file
  MAX_FILE_SIZE = 50.megabytes        # Massimo 50 MB per file
  MAX_PDF_PAGES = 1000               # Massimo 1000 pagine per PDF
  FILE_PROCESSING_TIMEOUT = 30       # Timeout 30 secondi per file

  def generate_pdf
    return nil if expenses.empty?

    begin
      # Create main PDF with expense details using HexaPDF::Composer
      composer = HexaPDF::Composer.new(page_size: :A4, margin: 50)

      # Set default font and styles
      composer.style(:base, font: "Helvetica", font_size: 12)

      create_pdf_header(composer)
      create_pdf_body(composer)
      create_pdf_footer(composer)

      # If there are attachments, combine them with the main PDF
      if has_attachments?
        combine_with_attachments(composer.document)
      else
        io = StringIO.new
        composer.write(io, optimize: true)
        io.string
      end
    rescue StandardError => e
      Rails.logger.error "Error generating PDF for reimbursement #{id}: #{e.message}"
      puts "Error generating PDF: #{e.message}"
      puts e.backtrace
      nil
    end
  end

  private

  def has_attachments?
    expenses.any? { |expense| expense.attachment.attached? || expense.pdf_attachment.attached? }
  end

  def validate_file_before_processing!(file)
    """
    Valida il file prima di elaborarlo.
    Lancia un'eccezione se il file non è valido.
    """
    # 1. Verifica la dimensione
    file_size = file.byte_size
    raise StandardError, "File troppo grande (max #{MAX_FILE_SIZE.to_i / 1.megabyte}MB)" if file_size > MAX_FILE_SIZE
    raise StandardError, "File vuoto o corrotto" if file_size.zero?

    # 2. Verifica magic bytes per i PDF
    beginning = file.download[0..4]
    unless beginning.start_with?("%PDF")
      raise StandardError, "File non è un PDF valido (magic bytes assenti)"
    end
  end

  def validate_pdf_structure!(pdf_path)
    """
    Valida la struttura del PDF dopo l'apertura.
    Rimuove JavaScript e oggetti malevoli per la sicurezza.
    """
    begin
      doc = HexaPDF::Document.open(pdf_path)
      pages_count = doc.pages.count

      if pages_count > MAX_PDF_PAGES
        raise StandardError, "PDF contiene troppi pagine (#{pages_count} > #{MAX_PDF_PAGES})"
      end

      if pages_count.zero?
        raise StandardError, "PDF vuoto"
      end

      # Sanitizza il documento rimuovendo JavaScript e oggetti pericolosi
      sanitize_pdf!(doc)

      doc
    rescue HexaPDF::EncryptionError => e
      raise StandardError, "PDF protetto da password: #{e.message}"
    rescue HexaPDF::Error => e
      raise StandardError, "Struttura PDF corrotta: #{e.message}"
    end
  end

  def sanitize_pdf!(doc)
    """
    Rimuove JavaScript, azioni, e altri elementi potenzialmente pericolosi dal PDF.
    """
    # Rimuovi JavaScript a livello di documento
    if doc.catalog[:OpenAction]
      Rails.logger.warn "Rimosso OpenAction dal PDF"
      doc.catalog.delete(:OpenAction)
    end

    if doc.catalog[:AA]
      Rails.logger.warn "Rimosso Additional Actions (AA) dal PDF"
      doc.catalog.delete(:AA)
    end

    # Rimuovi JavaScript dai nomi del catalogo
    if doc.catalog[:Names] && doc.catalog[:Names][:JavaScript]
      Rails.logger.warn "Rimosso JavaScript Name Tree dal PDF"
      doc.catalog[:Names].delete(:JavaScript)
    end

    # Itera attraverso tutte le pagine e rimuovi azioni/JavaScript
    doc.pages.each do |page|
      next unless page.data

      # Rimuovi azioni dalla pagina
      if page[:AA]
        Rails.logger.warn "Rimosso Additional Actions da pagina"
        page.delete(:AA)
      end

      if page[:OpenAction]
        Rails.logger.warn "Rimosso OpenAction da pagina"
        page.delete(:OpenAction)
      end

      # Rimuovi azioni da annotazioni
      if page[:Annots]
        page[:Annots].each do |annot|
          next unless annot

          if annot[:AA]
            Rails.logger.warn "Rimosso Additional Actions da annotazione"
            annot.delete(:AA)
          end

          if annot[:A]
            # Verifica se l'azione contiene JavaScript
            action = annot[:A]
            if action.is_a?(Hash) && (action[:S] == :JavaScript || action[:JS])
              Rails.logger.warn "Rimosso JavaScript Action da annotazione"
              annot.delete(:A)
            end
          end
        end
      end
    end

    # Rimuovi oggetti JavaScript dal document object store
    doc.objects.each do |obj|
      next unless obj.is_a?(Hash)

      # Rimuovi stream JavaScript
      if obj[:S] == :JavaScript || obj[:Type] == :JavaScript
        Rails.logger.warn "Rimosso oggetto JavaScript dal PDF"
        # Marca per eliminazione (HexaPDF pulirà i riferimenti)
        next
      end

      # Rimuovi azioni contenenti JavaScript
      if obj[:A].is_a?(Hash)
        action = obj[:A]
        if action[:S] == :JavaScript || action[:JS]
          Rails.logger.warn "Rimosso JavaScript Action"
          obj.delete(:A)
        end
      end
    end
  end

  def safe_process_file_with_timeout(file, &block)
    """
    Processa il file con timeout per prevenire blocchi infiniti.
    """
    Timeout.timeout(FILE_PROCESSING_TIMEOUT) do
      yield(file)
    end
  rescue Timeout::Error
    raise StandardError, "Elaborazione file scaduta - file potrebbe essere malevolo"
  end

  def combine_with_attachments(main_doc)
    # Create combined PDF using HexaPDF (more robust than CombinePDF)
    target_doc = HexaPDF::Document.new

    # Add main PDF pages
    main_doc.pages.each { |page| target_doc.pages << target_doc.import(page) }

    # Add attachment pages for each expense
    expenses.each do |expense|
      # Handle PDF attachment (electronic invoice)
      if expense.pdf_attachment.attached?
        begin
          temp_invoice = Tempfile.new([ "invoice", ".pdf" ])
          temp_invoice.binmode
          invoice_data = expense.pdf_attachment.download

          # Validazione del file prima del salvataggio
          validate_file_before_processing!(expense.pdf_attachment)

          temp_invoice.write(invoice_data)
          temp_invoice.close

          # Processa con timeout e validazione struttura
          safe_process_file_with_timeout(temp_invoice) do |file|
            invoice_doc = validate_pdf_structure!(file.path)
            invoice_doc.pages.each { |page| target_doc.pages << target_doc.import(page) }
          end

          temp_invoice.unlink
        rescue Timeout::Error => e
          Rails.logger.error "Timeout elaborazione fattura #{expense.id}: #{e.message}"
        rescue StandardError => e
          Rails.logger.error "Errore fattura #{expense.id}: #{e.message}"
        end
      end

      # Handle receipt attachments
      next unless expense.attachment.attached?

      receipt = expense.attachment
      begin
        # Validazione del file prima del processamento
        validate_file_before_processing!(receipt)

        if receipt.content_type == "application/pdf"
          # For PDF receipts, try to open with HexaPDF (handles most encrypted PDFs automatically)
          temp_receipt = Tempfile.new([ "receipt", ".pdf" ])
          temp_receipt.binmode
          receipt_data = receipt.download
          temp_receipt.write(receipt_data)
          temp_receipt.close

          begin
            # Processa con timeout e validazione struttura
            safe_process_file_with_timeout(temp_receipt) do |file|
              receipt_doc = validate_pdf_structure!(file.path)
              receipt_doc.pages.each { |page| target_doc.pages << target_doc.import(page) }
            end
          rescue HexaPDF::EncryptionError => e
            Rails.logger.error "PDF ricevuta #{receipt.filename} è protetto da password: #{e.message}"
            raise StandardError, "PDF #{receipt.filename} è protetto da password e non può essere elaborato"
          end

          temp_receipt.unlink
        else
          # For image receipts, convert to PDF first using HexaPDF
          temp_image = Tempfile.new([ "receipt", receipt.filename.extension ])
          temp_image.binmode
          receipt_data = receipt.download
          temp_image.write(receipt_data)
          temp_image.close

          # Processa con timeout
          safe_process_file_with_timeout(temp_image) do |file|
            # Create a temporary PDF with the image using HexaPDF
            image_composer = HexaPDF::Composer.new
            image_composer.image(file.path,
                                width: image_composer.frame.width,
                                height: image_composer.frame.height,
                                position: :center)

            temp_image_pdf = Tempfile.new([ "receipt_pdf", ".pdf" ])
            temp_image_pdf.close
            image_composer.write(temp_image_pdf.path)

            image_doc = HexaPDF::Document.open(temp_image_pdf.path)
            image_doc.pages.each { |page| target_doc.pages << target_doc.import(page) }

            File.unlink(temp_image_pdf.path)
          end

          temp_image.unlink
        end
      rescue Timeout::Error => e
        Rails.logger.error "Timeout elaborazione ricevuta #{expense.id}: #{e.message}"
      rescue StandardError => e
        Rails.logger.error "Errore ricevuta #{expense.id}: #{e.message}"
      end
    end

    # Write combined PDF to string
    io = StringIO.new
    target_doc.write(io, optimize: true)
    io.string
  rescue StandardError => e
    Rails.logger.error "Errore combinazione PDF: #{e.message}"
    puts "Errore combinazione PDF: #{e.message}"
    puts e.backtrace
    # Fallback to main PDF only
    io = StringIO.new
    main_doc.write(io, optimize: true)
    io.string
  end

  def create_pdf_header(composer)
    composer.text("Rimborso ##{id}", font_size: 20,
                  font: "Helvetica bold",
                  margin: [ 0, 0, 20 ])

    # Informazioni utente
    composer.text("Richiedente: #{user.name} #{user.surname}", font_size: 14)
    composer.text("Email: #{user.email}", font_size: 12)
    composer.text("Data creazione: #{created_at.strftime('%d/%m/%Y')}", font_size: 12)
    composer.text("Totale: € #{number_with_precision(total_amount, precision: 2)}",
                  font_size: 14,
                  font: "Helvetica bold",
                  margin: [ 0, 0, 20 ])

    # Note del rimborso se presenti
    if notes.any?
      composer.text("Note:", font_size: 14,
                    font: "Helvetica bold")
      notes.each do |note|
        composer.text("- #{note.text}", font_size: 10)
      end
      composer.text("", margin: [ 0, 0, 15 ])
    end
  end

  def create_pdf_body(composer)
    composer.text("Dettaglio Spese:", font_size: 16,
                  font: "Helvetica bold",
                  margin: [ 0, 0, 10 ])

    expenses.each_with_index do |expense, index|
      composer.text("#{index + 1}. #{expense.id} #{expense.purpose}",
                    font_size: 14,
                    font: "Helvetica bold",
                    margin: [ 0, 0, 5 ])

      # Informazioni base
      composer.text("Data: #{expense.date.strftime('%d/%m/%Y')}", font_size: 11)
      composer.text("Importo spesa: € #{number_with_precision(expense.amount, precision: 2)}", font_size: 11)

      if expense.requested_amount != expense.amount
        composer.formatted_text([ { text: "Importo richiesto: € #{number_with_precision(expense.requested_amount, precision: 2)}",
                                  font: "Helvetica bold",
                                  font_size: 11 } ], fill_color: "0066CC")
      else
        composer.text("Importo richiesto: € #{number_with_precision(expense.requested_amount, precision: 2)}", font_size: 11)
      end

      composer.text("Fondo: #{expense.fund.name}", font_size: 11)
      composer.text("Progetto: #{expense.project}", font_size: 11)

      # Se è una spesa auto, mostra i dettagli specifici
      if expense.car?
        create_car_expense_details(composer, expense)
      else
        create_regular_expense_details(composer, expense)
      end

      composer.text("Stato: #{expense.status_in_italian}", font_size: 10,
                    font: "Helvetica bold",
                    margin: [ 0, 0, 10 ])

      # Aggiungi una linea separatrice se non è l'ultima spesa
      if index < expenses.count - 1
        composer.canvas.line_width(1)
                       .line(composer.frame.left, composer.y, composer.frame.right, composer.y)
                       .stroke
        composer.text("", margin: [ 0, 0, 8 ])
      end
    end
  end

  def create_car_expense_details(composer, expense)
    composer.text("", margin: [ 0, 0, 5 ])
    composer.formatted_text([ { text: "RIMBORSO SPESE CHILOMETRICO PER TRASPORTO IN AUTO - Dettagli:",
                              font: "Helvetica bold",
                              font_size: 12 } ], fill_color: "0066CC")
    composer.text("Data calcolo: #{expense.calculation_date&.strftime('%d/%m/%Y')}", font_size: 10)
    composer.text("Partenza: #{expense.departure}", font_size: 10)
    composer.text("Arrivo: #{expense.arrival}", font_size: 10)
    composer.text("Distanza: #{expense.distance} km", font_size: 10)
    composer.text("Andata e ritorno: #{expense.return_trip? ? 'Sì' : 'No'}", font_size: 10)

    if expense.vehicle
      composer.text("Veicolo: #{expense.vehicle.brand} #{expense.vehicle.model} #{expense.vehicle.fuel_label}", font_size: 10)
    end

    # Dettaglio costi
    composer.text("", margin: [ 0, 0, 3 ])
    composer.text("Costi per km:", font_size: 10,
                  font: "Helvetica bold")
    composer.text("- Quota capitale: €#{number_with_precision(expense.quota_capitale, precision: 2)}", font_size: 9)
    composer.text("- Carburante: €#{number_with_precision(expense.carburante, precision: 2)}", font_size: 9)
    composer.text("- Pneumatici: €#{number_with_precision(expense.pneumatici, precision: 2)}", font_size: 9)
    composer.text("- Manutenzione: €#{number_with_precision(expense.manutenzione, precision: 2)}", font_size: 9)

    total_per_km = expense.quota_capitale + expense.carburante + expense.pneumatici + expense.manutenzione
    total_distance = expense.return_trip? ? expense.distance * 2 : expense.distance
    composer.text("Totale per km: €#{number_with_precision(total_per_km, precision: 2)}", font_size: 9,
                  font: "Helvetica bold")
    composer.text("Distanza totale: #{total_distance} km", font_size: 9)
  end

  def create_regular_expense_details(composer, expense)
    # Gestione allegati per spese normali - solo riferimenti, i PDF saranno allegati alla fine
    if expense.pdf_attachment.attached?
      composer.formatted_text([ { text: "Fattura elettronica allegata", font_size: 10 } ], fill_color: "008800")
    elsif expense.attachment.attached?
      composer.formatted_text([ { text: "Ricevuta allegata", font_size: 10 } ], fill_color: "008800")
    end
  end

  def create_pdf_footer(composer)
    composer.text("", margin: [ 0, 0, 15 ])

    # Totale rimborso
    composer.text("Totale rimborso: € #{number_with_precision(total_amount, precision: 2)}",
                  font_size: 14,
                  font: "Helvetica bold",
                  margin: [ 0, 0, 15 ])

    # Informazioni pagamento
    if bank_account
      composer.text("Coordinate Bancarie:", font_size: 14,
                    font: "Helvetica bold")
      composer.text("IBAN: #{bank_account.iban}", font_size: 12)
      composer.text("Intestatario: #{bank_account.owner}", font_size: 12)
    end

    # Footer con data generazione
    composer.text("", margin: [ 0, 0, 30 ])
    composer.formatted_text([ { text: "Documento generato il #{Time.current.strftime('%d/%m/%Y alle %H:%M')}",
                              font_size: 8 } ], text_align: :right, fill_color: "666666")
  end
end
