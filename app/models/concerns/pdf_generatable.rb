require "combine_pdf"

module PdfGeneratable
  extend ActiveSupport::Concern
  include ActionView::Helpers::NumberHelper

  def generate_pdf
    return nil if expenses.empty?

    begin
      # Create main PDF with expense details
      pdf_content = Prawn::Document.new(margin: 50) do |pdf|
        pdf.font_families.update("OpenSans" => {
            normal: Rails.root.join("app/assets/fonts/OpenSans-Regular.ttf"),
            italic: Rails.root.join("app/assets/fonts/OpenSans-Italic.ttf"),
            bold: Rails.root.join("app/assets/fonts/OpenSans-Bold.ttf"),
            bold_italic: Rails.root.join("app/assets/fonts/OpenSans-BoldItalic.ttf")
          })
        pdf.font "OpenSans"

        create_pdf_header(pdf)
        create_pdf_body(pdf)
        create_pdf_footer(pdf)
      end.render

      # If there are attachments, combine them with the main PDF
      if has_attachments?
        combine_with_attachments(pdf_content)
      else
        pdf_content
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

  def combine_with_attachments(main_pdf_content)
    # Create combined PDF using CombinePDF
    combined_pdf = CombinePDF.new

    # Add main PDF
    main_temp = Tempfile.new([ "main_pdf", ".pdf" ])
    File.open(main_temp.path, "wb") { |f| f.write(main_pdf_content) }
    combined_pdf << CombinePDF.load(main_temp.path)
    main_temp.close
    main_temp.unlink

    # Add attachment pages for each expense
    expenses.each do |expense|
      # Handle PDF attachment (electronic invoice)
      if expense.pdf_attachment.attached?
        begin
          temp_invoice = Tempfile.new([ "invoice", ".pdf" ])
          temp_invoice.binmode
          temp_invoice.write(expense.pdf_attachment.download)
          temp_invoice.close

          invoice_pdf = CombinePDF.load(temp_invoice.path)
          combined_pdf << invoice_pdf

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
          # For PDF receipts, check if encrypted and handle accordingly
          temp_receipt = Tempfile.new([ "receipt", ".pdf" ])
          temp_receipt.binmode
          temp_receipt.write(receipt.download)
          temp_receipt.close

          # Check if PDF is encrypted using pdfinfo gem
          if pdf_encrypted?(temp_receipt.path)
            Rails.logger.info "PDF attachment #{receipt.filename} is encrypted, converting to image"
            converted_pdf = convert_encrypted_pdf_to_image(receipt, expense.id)
            combined_pdf << converted_pdf if converted_pdf
          else
            Rails.logger.info "PDF attachment #{receipt.filename} is not encrypted, processing normally"
            receipt_pdf = CombinePDF.load(temp_receipt.path)
            combined_pdf << receipt_pdf
          end

          temp_receipt.unlink
        else
          # For image receipts, convert to PDF first
          temp_image = Tempfile.new([ "receipt", receipt.filename.extension ])
          temp_image.binmode
          temp_image.write(receipt.download)
          temp_image.close

          # Create a temporary PDF with the image
          image_pdf = Prawn::Document.new do |pdf|
            pdf.image temp_image.path,
                     fit: [ pdf.bounds.width, pdf.bounds.height ],
                     position: :center
          end

          temp_image_pdf = Tempfile.new([ "receipt_pdf", ".pdf" ])
          File.open(temp_image_pdf.path, "wb") { |f| f.write(image_pdf.render) }

          combined_pdf << CombinePDF.load(temp_image_pdf.path)

          temp_image.unlink
          temp_image_pdf.close
          temp_image_pdf.unlink
        end
      rescue StandardError => e
        Rails.logger.error "Error adding receipt for expense #{expense.id}: #{e.message}"
      end
    end

    combined_pdf.to_pdf
  rescue StandardError => e
    Rails.logger.error "Error combining PDFs: #{e.message}"
    puts "Error combining PDFs: #{e.message}"
    puts e.backtrace
    main_pdf_content # Fallback to main PDF only
  end

  def create_pdf_header(pdf)
    pdf.text "Rimborso ##{id}", size: 20, style: :bold
    pdf.move_down 20

    # Informazioni utente
    pdf.text "Richiedente: #{user.name} #{user.surname}", size: 14
    pdf.text "Email: #{user.email}", size: 12
    pdf.text "Data creazione: #{created_at.strftime('%d/%m/%Y')}", size: 12
    pdf.text "Totale: € #{number_with_precision(total_amount, precision: 2)}", size: 14, style: :bold
    pdf.move_down 20

    # Note del rimborso se presenti
    if notes.any?
      pdf.text "Note:", size: 14, style: :bold
      notes.each do |note|
        pdf.text "- #{note.text}", size: 10
      end
      pdf.move_down 15
    end
  end

  def create_pdf_body(pdf)
    pdf.text "Dettaglio Spese:", size: 16, style: :bold
    pdf.move_down 10

    expenses.each_with_index do |expense, index|
      pdf.text "#{index + 1}. #{expense.id} #{expense.purpose}", size: 14, style: :bold
      pdf.move_down 5

      # Informazioni base
      pdf.text "Data: #{expense.date.strftime('%d/%m/%Y')}", size: 11
      pdf.text "Importo spesa: € #{number_with_precision(expense.amount, precision: 2)}", size: 11
      if expense.requested_amount != expense.amount
        pdf.text "Importo richiesto: € #{number_with_precision(expense.requested_amount, precision: 2)}", size: 11, style: :bold, color: "0066CC"
      else
        pdf.text "Importo richiesto: € #{number_with_precision(expense.requested_amount, precision: 2)}", size: 11
      end
      pdf.text "Fondo: #{expense.fund.name}", size: 11
      pdf.text "Progetto: #{expense.project}", size: 11

      # Se è una spesa auto, mostra i dettagli specifici
      if expense.car?
        create_car_expense_details(pdf, expense)
      else
        create_regular_expense_details(pdf, expense)
      end

      pdf.text "Stato: #{expense.status_in_italian}", size: 10, style: :bold
      pdf.move_down 10

      # Aggiungi una linea separatrice se non è l'ultima spesa
      if index < expenses.count - 1
        pdf.stroke_horizontal_rule
        pdf.move_down 8
      end
    end
  end

  def create_car_expense_details(pdf, expense)
    pdf.move_down 5
    pdf.text "RIMBORSO SPESE CHILOMETRICO PER TRASPORTO IN AUTO - Dettagli:", size: 12, style: :bold, color: "0066CC"
    pdf.text "Data calcolo: #{expense.calculation_date&.strftime('%d/%m/%Y')}", size: 10
    pdf.text "Partenza: #{expense.departure}", size: 10
    pdf.text "Arrivo: #{expense.arrival}", size: 10
    pdf.text "Distanza: #{expense.distance} km", size: 10
    pdf.text "Andata e ritorno: #{expense.return_trip? ? 'Sì' : 'No'}", size: 10

    if expense.vehicle
      pdf.text "Veicolo: #{expense.vehicle.brand} #{expense.vehicle.model} #{expense.vehicle.fuel_label}", size: 10
    end

    # Dettaglio costi
    pdf.move_down 3
    pdf.text "Costi per km:", size: 10, style: :bold
    pdf.text "- Quota capitale: €#{number_with_precision(expense.quota_capitale, precision: 2)}", size: 9
    pdf.text "- Carburante: €#{number_with_precision(expense.carburante, precision: 2)}", size: 9
    pdf.text "- Pneumatici: €#{number_with_precision(expense.pneumatici, precision: 2)}", size: 9
    pdf.text "- Manutenzione: €#{number_with_precision(expense.manutenzione, precision: 2)}", size: 9

    total_per_km = expense.quota_capitale + expense.carburante + expense.pneumatici + expense.manutenzione
    total_distance = expense.return_trip? ? expense.distance * 2 : expense.distance
    pdf.text "Totale per km: €#{number_with_precision(total_per_km, precision: 2)}", size: 9, style: :bold
    pdf.text "Distanza totale: #{total_distance} km", size: 9
  end

  def create_regular_expense_details(pdf, expense)
    # Gestione allegati per spese normali - solo riferimenti, i PDF saranno allegati alla fine
    if expense.pdf_attachment.attached?
      pdf.text "Fattura elettronica allegata", size: 10, color: "008800"
    elsif expense.attachment.attached?
      pdf.text "Ricevuta allegata", size: 10, color: "008800"
    end
  end

  def create_pdf_footer(pdf)
    pdf.move_down 15

    # Totale rimborso
    pdf.text "Totale rimborso: € #{number_with_precision(total_amount, precision: 2)}", size: 14, style: :bold
    pdf.move_down 15

    # Informazioni pagamento
    if bank_account
      pdf.text "Coordinate Bancarie:", size: 14, style: :bold
      pdf.text "IBAN: #{bank_account.iban}", size: 12
      pdf.text "Intestatario: #{bank_account.owner}", size: 12
    end

    # Footer con data generazione
    pdf.move_down 30
    pdf.text "Documento generato il #{Time.current.strftime('%d/%m/%Y alle %H:%M')}",
             size: 8, align: :right, color: "666666"
  end

  # Verifica se un PDF è crittografato usando la gem pdfinfo
  def pdf_encrypted?(pdf_path)
    begin
      pdf_info = Pdfinfo.new(pdf_path)
      encrypted = pdf_info.encrypted?

      Rails.logger.info "PDF encryption check for #{File.basename(pdf_path)}: #{encrypted ? 'encrypted' : 'not encrypted'}"

      encrypted
    rescue => e
      Rails.logger.error "Error checking PDF encryption for #{File.basename(pdf_path)}: #{e.message}"
      # In caso di errore, assumiamo che sia crittografato per evitare di bloccare il processo
      true
    end
  end

  # Converte un PDF crittografato in immagine usando Active Storage Previewer
  def convert_encrypted_pdf_to_image(attachment, expense_id)
    begin
      Rails.logger.info "Converting encrypted PDF #{attachment.filename} to image using Active Storage Previewer"

      # Usa Active Storage Previewer per generare un'anteprima del PDF
      # Active Storage usa pdftoppm internamente per i PDF e gestisce automaticamente la cache

      # Verifica se l'attachment può essere previsualizato
      unless attachment.previewable?
        Rails.logger.warn "PDF #{attachment.filename} is not previewable, falling back to notice"
        return create_encrypted_pdf_fallback_notice(attachment.filename.to_s)
      end

      # Genera l'anteprima usando Active Storage
      # Usa resize_to_fit per mantenere le proporzioni e ottenere alta risoluzione
      # 2480x3508 è A4 a 300 DPI (alta qualità per documenti)
      preview = attachment.preview(resize_to_fit: [ 2480, 3508 ])

      Rails.logger.info "Preview object created for #{attachment.filename}, forcing processing..."

      # Forza il processing sincrono della preview
      processed_preview = preview.processed

      Rails.logger.info "Preview processing completed for #{attachment.filename}"

      # Scarica l'anteprima generata (PNG ad alta qualità)
      preview_image_data = processed_preview.download

      Rails.logger.info "Generated preview for #{attachment.filename}: #{preview_image_data.bytesize} bytes"

      # Crea un nuovo PDF con l'immagine dell'anteprima
      converted_pdf_content = Prawn::Document.new(page_size: "A4", margin: 20) do |pdf|
        # Crea un file temporaneo per l'immagine di anteprima
        temp_preview = Tempfile.new([ "preview_image", ".png" ])
        temp_preview.binmode
        temp_preview.write(preview_image_data)
        temp_preview.close

        begin
          # Aggiungi l'immagine al PDF mantenendo le proporzioni
          pdf.image temp_preview.path,
                   fit: [ pdf.bounds.width, pdf.bounds.height - 30 ], # Lascia spazio per la nota
                   position: :center,
                   vposition: :top

          # Aggiungi una nota discreta che indica la conversione
          pdf.move_down 10
          pdf.text "Nota: Documento convertito da PDF protetto per la visualizzazione nel rimborso.",
                  size: 8, style: :italic, color: "666666", align: :center

        ensure
          temp_preview.unlink
        end
      end

      # Salva il PDF convertito in un file temporaneo e caricalo con CombinePDF
      temp_converted_pdf = Tempfile.new([ "converted_from_preview", ".pdf" ])
      temp_converted_pdf.binmode
      temp_converted_pdf.write(converted_pdf_content.render)
      temp_converted_pdf.close

      # Carica il PDF convertito con CombinePDF per l'uso nella combinazione
      result = CombinePDF.load(temp_converted_pdf.path)
      temp_converted_pdf.unlink

      Rails.logger.info "Successfully converted encrypted PDF #{attachment.filename} to image-based PDF using Active Storage Previewer (#{result.pages.count} pages)"
      result

    rescue => e
      Rails.logger.error "Error converting encrypted PDF #{attachment.filename} using Active Storage Previewer: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")

      # Fallback: crea un PDF con messaggio di errore
      Rails.logger.info "Falling back to encrypted PDF notice for #{attachment.filename}"
      create_encrypted_pdf_fallback_notice(attachment.filename.to_s)
    end
  end

  # Crea un PDF di notifica per file crittografati che non possono essere convertiti
  def create_encrypted_pdf_fallback_notice(filename)
    begin
      notice_pdf_content = Prawn::Document.new do |pdf|
        pdf.text "🔒 DOCUMENTO PROTETTO", size: 20, style: :bold, align: :center
        pdf.move_down 20

        pdf.text "Il seguente allegato è protetto e non può essere visualizzato:", size: 12, align: :center
        pdf.move_down 10

        pdf.text "\"#{filename}\"", size: 14, align: :center, style: :italic
        pdf.move_down 20

        pdf.text "Il documento originale è disponibile separatamente", size: 10, align: :center, color: "666666"
        pdf.move_down 30

        pdf.text "Sistema di Gestione Rimborsi", size: 8, align: :right, color: "999999"
        pdf.text "Documento generato automaticamente", size: 8, align: :right, color: "999999"
      end

      # Salva e carica con CombinePDF
      temp_notice = Tempfile.new([ "encrypted_notice", ".pdf" ])
      temp_notice.write(notice_pdf_content.render)
      temp_notice.close

      result = CombinePDF.load(temp_notice.path)
      temp_notice.unlink

      Rails.logger.info "Created fallback notice for encrypted PDF: #{filename}"
      result

    rescue => e
      Rails.logger.error "Error creating fallback notice for #{filename}: #{e.message}"
      nil
    end
  end
end
