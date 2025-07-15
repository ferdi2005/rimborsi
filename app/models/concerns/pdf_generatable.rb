require "pdf-reader"

module PdfGeneratable
  extend ActiveSupport::Concern

  def generate_pdf
    Prawn::Document.new do |pdf|
      # Header del documento
      pdf.text "Rimborso ##{id}", size: 20, style: :bold
      pdf.move_down 20

      # Informazioni utente
      pdf.text "Richiedente: #{user.name} #{user.surname}", size: 14
      pdf.text "Email: #{user.email}", size: 12
      pdf.text "Data creazione: #{created_at.strftime('%d/%m/%Y')}", size: 12
      pdf.text "Totale: € #{total_amount}", size: 14, style: :bold
      pdf.move_down 20

      # Note del rimborso se presenti
      if notes.any?
        pdf.text "Note:", size: 14, style: :bold
        notes.each do |note|
          pdf.text "- #{note.text}", size: 10
        end
        pdf.move_down 15
      end

      # Dettaglio spese
      pdf.text "Dettaglio Spese:", size: 16, style: :bold
      pdf.move_down 10

      # Dettaglio di ogni spesa con informazioni specifiche
      expenses.each_with_index do |expense, index|
        pdf.text "#{index + 1}. #{expense.id} #{expense.purpose}", size: 14, style: :bold
        pdf.move_down 5

        # Informazioni base
        pdf.text "Data: #{expense.date.strftime('%d/%m/%Y')}", size: 11
        pdf.text "Importo: € #{expense.amount}", size: 11
        pdf.text "Fondo: #{expense.fund.name}", size: 11
        pdf.text "Progetto: #{expense.project}", size: 11

        # Se è una spesa auto, mostra i dettagli specifici
        if expense.car?
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
          pdf.text "- Quota capitale: €#{expense.quota_capitale}", size: 9
          pdf.text "- Carburante: €#{expense.carburante}", size: 9
          pdf.text "- Pneumatici: €#{expense.pneumatici}", size: 9
          pdf.text "- Manutenzione: €#{expense.manutenzione}", size: 9

          total_per_km = expense.quota_capitale + expense.carburante + expense.pneumatici + expense.manutenzione
          total_distance = expense.return_trip? ? expense.distance * 2 : expense.distance
          pdf.text "Totale per km: €#{total_per_km}", size: 9, style: :bold
          pdf.text "Distanza totale: #{total_distance} km", size: 9
        else
          # Gestione allegati per spese normali
          if expense.electronic_invoice? && expense.has_invoice_pdf?
            pdf.text "Fattura elettronica allegata", size: 10, color: "008800"

            # Aggiungi il PDF della fattura elettronica
            begin
              pdf_content = expense.pdf_attachment.download
              temp_pdf = Tempfile.new([ "invoice_pdf", ".pdf" ])
              temp_pdf.binmode
              temp_pdf.write(pdf_content)
              temp_pdf.close

              pdf.start_new_page
              pdf.text "Fattura Elettronica - Expense ##{expense.id}", size: 14, style: :bold
              pdf.move_down 10

              # Inserisce il PDF della fattura elettronica
              pdf_pages = PDF::Reader.new(temp_pdf.path).page_count
              (1..pdf_pages).each do |page_num|
                pdf.start_new_page unless page_num == 1
                pdf.image temp_pdf.path,
                         fit: [ pdf.bounds.width, pdf.bounds.height ],
                         position: :center,
                         page: page_num
              end

              temp_pdf.unlink
            rescue => e
              Rails.logger.error "Errore nell'inserimento del PDF della fattura elettronica: #{e.message}"
              pdf.text "Errore nel caricamento del PDF della fattura elettronica", size: 10, color: "FF0000"
            end

          elsif expense.attachment.attached?
            # Aggiungi l'allegato (immagine o PDF)
            begin
              attachment_content = expense.attachment.download
              content_type = expense.attachment.content_type
              filename = expense.attachment.filename.to_s

              pdf.start_new_page
              pdf.text "Ricevuta - Spesa ##{expense.id}: #{filename}", size: 14, style: :bold
              pdf.move_down 10

              if content_type.start_with?("image/")
                # Per le immagini
                temp_image = Tempfile.new([ "attachment", File.extname(filename) ])
                temp_image.binmode
                temp_image.write(attachment_content)
                temp_image.close

                pdf.image temp_image.path,
                         fit: [ pdf.bounds.width, pdf.bounds.height - 50 ],
                         position: :center

                temp_image.unlink

              elsif content_type == "application/pdf"
                # Per i PDF
                temp_pdf = Tempfile.new([ "attachment", ".pdf" ])
                temp_pdf.binmode
                temp_pdf.write(attachment_content)
                temp_pdf.close

                # Inserisce tutte le pagine del PDF allegato
                pdf_pages = PDF::Reader.new(temp_pdf.path).page_count
                (1..pdf_pages).each do |page_num|
                  pdf.start_new_page unless page_num == 1
                  pdf.image temp_pdf.path,
                           fit: [ pdf.bounds.width, pdf.bounds.height ],
                           position: :center,
                           page: page_num
                end

                temp_pdf.unlink
              else
                pdf.text "Formato file non supportato per l'inclusione: #{content_type}", size: 10, color: "FF6600"
              end

            rescue => e
              Rails.logger.error "Errore nell'inserimento dell'allegato: #{e.message}"
              pdf.text "Errore nel caricamento dell'allegato", size: 10, color: "FF0000"
            end
          end
        end

        pdf.text "Stato: #{expense.status_in_italian}", size: 10, style: :bold
        pdf.move_down 10

        # Aggiungi una linea separatrice se non è l'ultima spesa
        if index < expenses.count - 1
          pdf.stroke_horizontal_rule
          pdf.move_down 8
        end
      end

      pdf.move_down 15

      # Totale rimborso
      pdf.text "Totale rimborso: € #{total_amount}", size: 14, style: :bold
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
    end.render
  end
end
