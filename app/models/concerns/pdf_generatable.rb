require "combine_pdf"

module PdfGeneratable
  extend ActiveSupport::Concern
  include ActionView::Helpers::NumberHelper

  def generate_pdf
    return nil if expenses.empty?

    begin
      # Create main PDF with expense details
      pdf_content = Prawn::Document.new(margin: 50) do |pdf|
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
          # For PDF receipts, add all pages
          temp_receipt = Tempfile.new([ "receipt", ".pdf" ])
          temp_receipt.binmode
          temp_receipt.write(receipt.download)
          temp_receipt.close

          receipt_pdf = CombinePDF.load(temp_receipt.path)
          combined_pdf << receipt_pdf

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
end
