require "hexapdf"

module PdfGeneratable
  extend ActiveSupport::Concern
  include ActionView::Helpers::NumberHelper

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
          temp_invoice.write(expense.pdf_attachment.download)
          temp_invoice.close

          # Load PDF with HexaPDF (handles problematic PDFs automatically)
          invoice_doc = HexaPDF::Document.open(temp_invoice.path)
          invoice_doc.pages.each { |page| target_doc.pages << target_doc.import(page) }

          temp_invoice.unlink
        rescue StandardError => e
          Rails.logger.error "Error adding invoice PDF: #{e.message}"
        end
      end

      # Handle receipt attachments
      next unless expense.attachment.attached?

      receipt = expense.attachment
      begin
        if receipt.content_type == "application/pdf"
          # For PDF receipts, try to open with HexaPDF (handles most encrypted PDFs automatically)
          temp_receipt = Tempfile.new([ "receipt", ".pdf" ])
          temp_receipt.binmode
          temp_receipt.write(receipt.download)
          temp_receipt.close

          begin
            # HexaPDF can handle encrypted PDFs without passwords automatically
            receipt_doc = HexaPDF::Document.open(temp_receipt.path)
            receipt_doc.pages.each { |page| target_doc.pages << target_doc.import(page) }
          rescue HexaPDF::EncryptionError => e
            Rails.logger.error "PDF attachment #{receipt.filename} is password-protected and cannot be processed: #{e.message}"
            raise StandardError, "PDF #{receipt.filename} è protetto da password e non può essere elaborato"
          end

          temp_receipt.unlink
        else
          # For image receipts, convert to PDF first using HexaPDF
          temp_image = Tempfile.new([ "receipt", receipt.filename.extension ])
          temp_image.binmode
          temp_image.write(receipt.download)
          temp_image.close

          # Create a temporary PDF with the image using HexaPDF
          image_composer = HexaPDF::Composer.new
          image_composer.image(temp_image.path,
                              width: image_composer.frame.width,
                              height: image_composer.frame.height,
                              position: :center)

          temp_image_pdf = Tempfile.new([ "receipt_pdf", ".pdf" ])
          temp_image_pdf.close
          image_composer.write(temp_image_pdf.path)

          image_doc = HexaPDF::Document.open(temp_image_pdf.path)
          image_doc.pages.each { |page| target_doc.pages << target_doc.import(page) }

          temp_image.unlink
          File.unlink(temp_image_pdf.path)
        end
      rescue StandardError => e
        Rails.logger.error "Error adding receipt for expense #{expense.id}: #{e.message}"
      end
    end

    # Write combined PDF to string
    io = StringIO.new
    target_doc.write(io, optimize: true)
    io.string
  rescue StandardError => e
    Rails.logger.error "Error combining PDFs: #{e.message}"
    puts "Error combining PDFs: #{e.message}"
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
