class ProcessPaymentJob < ApplicationJob
  queue_as :default

  def perform(payment_id)
    payment = Payment.find(payment_id)
    return unless payment.status_paid?

    failed_reimboursements = []

    payment.reimboursements.each do |reimboursement|
      begin
        process_reimboursement(reimboursement)
        Rails.logger.info "Successfully processed reimboursement #{reimboursement.id}"
      rescue StandardError => e
        Rails.logger.error "Error processing reimboursement #{reimboursement.id}: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")

        # Aggiungi il rimborso alla lista dei falliti
        failed_reimboursements << reimboursement.id
      end
    end

    # Se ci sono stati errori, riporta l'intero pagamento a "created"
    if failed_reimboursements.any?
      Rails.logger.error "Failed to process reimboursements: #{failed_reimboursements.join(', ')}"
      Rails.logger.error "Reverting payment #{payment.id} to 'created' status"

      # Riporta l'intero pagamento allo stato "created"
      payment.revert_to_created!

      # Inserire eventuale notifica
    end
  end

  # private

  def process_reimboursement(reimboursement)
    # Genera il PDF per il rimborso
    pdf_content = generate_reimboursement_pdf(reimboursement)

    # Carica il PDF e le ricevute su NextCloud
    upload_files_to_nextcloud(reimboursement, pdf_content)
  end

  def generate_reimboursement_pdf(reimboursement)
    require 'prawn'

    Prawn::Document.new do |pdf|
      # Header del documento
      pdf.text "Rimborso ##{reimboursement.id}", size: 20, style: :bold
      pdf.move_down 20

      # Informazioni utente
      pdf.text "Utente: #{reimboursement.user.name}", size: 14
      pdf.text "Email: #{reimboursement.user.email}", size: 12
      pdf.text "Data creazione: #{reimboursement.created_at.strftime('%d/%m/%Y')}", size: 12
      pdf.text "Totale: €#{reimboursement.total_amount}", size: 14, style: :bold
      pdf.move_down 20

      # Note del rimborso se presenti
      if reimboursement.notes.any?
        pdf.text "Note:", size: 14, style: :bold
        reimboursement.notes.each do |note|
          pdf.text "- #{note.text}", size: 10
        end
        pdf.move_down 15
      end

      # Dettaglio spese
      pdf.text "Dettaglio Spese:", size: 16, style: :bold
      pdf.move_down 10

      # Dettaglio di ogni spesa con informazioni specifiche
      reimboursement.expenses.each_with_index do |expense, index|
        pdf.text "#{index + 1}. #{expense.id} #{expense.purpose}", size: 14, style: :bold
        pdf.move_down 5

        # Informazioni base
        pdf.text "Data: #{expense.date.strftime('%d/%m/%Y')}", size: 11
        pdf.text "Importo: €#{expense.amount}", size: 11
        pdf.text "Progetto: #{expense.project.name}", size: 11

        # Se è una spesa auto, mostra i dettagli specifici
        if expense.car?
          pdf.move_down 5
          pdf.text "RIMBORSO SPESE CHILOMETRICO PER TRASPORTO IN AUTO - Dettagli:", size: 12, style: :bold, color: '0066CC'
          pdf.text "Data calcolo: #{expense.calculation_date&.strftime('%d/%m/%Y')}", size: 10
          pdf.text "Partenza: #{expense.departure}", size: 10
          pdf.text "Arrivo: #{expense.arrival}", size: 10
          pdf.text "Distanza: #{expense.distance} km", size: 10
          pdf.text "Andata e ritorno: #{expense.return_trip? ? 'Sì' : 'No'}", size: 10

          if expense.vehicle
            pdf.text "Veicolo:  #{expense.vehicle.brand} #{expense.vehicle.brand} #{expense.vehicle.brand} #{expense.vehicle.model} #{expense.vehicle.fuel_label}", size: 10
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
            pdf.text "Fornitore: #{expense.supplier}", size: 10, color: '0066CC'
          if expense.attachment.attached?
            pdf.text "Ricevuta allegata: #{expense.attachment.filename}", size: 10, color: '008800'
          end
        end

        pdf.text "Stato: #{expense.status_in_italian}", size: 10, style: :bold
        pdf.move_down 10

        # Aggiungi una linea separatrice se non è l'ultima spesa
        if index < reimboursement.expenses.count - 1
          pdf.stroke_horizontal_rule
          pdf.move_down 8
        end
      end

      pdf.move_down 15

      # Totale rimborso
      pdf.text "Totale rimborso: €#{reimboursement.total_amount}", size: 14, style: :bold
      pdf.move_down 15

      # Informazioni pagamento
      if reimboursement.bank_account
        pdf.text "Coordinate Bancarie:", size: 14, style: :bold
        pdf.text "IBAN: #{reimboursement.bank_account.iban}", size: 12
        pdf.text "Intestatario: #{reimboursement.bank_account.owner}", size: 12
      end

      # Footer con data generazione
      pdf.move_down 30
      pdf.text "Documento generato il #{Time.current.strftime('%d/%m/%Y alle %H:%M')}",
               size: 8, align: :right, color: '666666'
    end.render
  end

  def upload_files_to_nextcloud(reimboursement, pdf_content)
    require 'net/http'
    require 'uri'
    require 'base64'

    nextcloud_url = ENV['NEXTCLOUD_WEBDAV_URL']
    username = ENV['NEXTCLOUD_USERNAME']
    password = ENV['NEXTCLOUD_PASSWORD']
    admin_folder = ENV['CARTELLA_AMMINISTRAZIONE']

    raise 'NextCloud configuration missing' if [nextcloud_url, username, password, admin_folder].any?(&:blank?)

    # Costruisci il path di destinazione con cartella data
    user_folder = reimboursement.user.email.split('@').first # username dall'email
    date_folder = Date.current.strftime('%Y-%m-%d')
    rimborso_folder = "rimborso_#{reimboursement.id}"

    base_path = "#{admin_folder}/#{user_folder}/#{date_folder}/#{rimborso_folder}"

    # Crea tutte le directory necessarie
    base_uri = URI(nextcloud_url)
    ensure_directory_exists(base_uri, username, password, base_path)

    # Carica il PDF del rimborso
    pdf_path = "#{base_path}/rimborso_#{reimboursement.id}.pdf"
    upload_file_to_nextcloud(nextcloud_url, pdf_path, pdf_content, 'application/pdf', username, password)

    Rails.logger.info "Successfully uploaded PDF for reimboursement #{reimboursement.id} to #{pdf_path}"

    # Carica le ricevute allegate
    uploaded_receipts = 0
    reimboursement.expenses.each do |expense|
      if expense.attachment.attached?
        begin
          # Scarica il file da Active Storage
          attachment_content = expense.attachment.download

          # Determina il tipo di contenuto
          content_type = expense.attachment.content_type || 'application/octet-stream'

          # Costruisci il nome del file con prefisso spesa
          filename = "spesa_#{expense.id}_#{expense.attachment.filename}"
          receipt_path = "#{base_path}/#{filename}"

          # Carica la ricevuta
          upload_file_to_nextcloud(nextcloud_url, receipt_path, attachment_content, content_type, username, password)

          uploaded_receipts += 1
          Rails.logger.info "Successfully uploaded receipt for expense #{expense.id}: #{filename}"

        rescue StandardError => e
          Rails.logger.error "Failed to upload receipt for expense #{expense.id}: #{e.message}"
          # Continua con le altre ricevute anche se una fallisce
        end
      end
    end

    Rails.logger.info "Successfully uploaded #{uploaded_receipts} receipts for reimboursement #{reimboursement.id}"
  end

  def upload_file_to_nextcloud(nextcloud_url, remote_path, content, content_type, username, password)
    webdav_url = "#{nextcloud_url}/#{remote_path}"
    uri = URI(webdav_url)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'

    request = Net::HTTP::Put.new(uri)
    request.basic_auth(username, password)
    request['Content-Type'] = content_type
    request.body = content

    response = http.request(request)

    unless response.code.to_i.between?(200, 299)
      raise "Failed to upload file to NextCloud: #{response.code} #{response.message} - Path: #{remote_path}"
    end
  end

  def ensure_directory_exists(base_uri, username, password, directory_path)
    path_parts = directory_path.split('/')
    current_path = ''

    path_parts.each do |part|
      next if part.blank?

      current_path += "/#{part}"
      dir_uri = URI("#{base_uri.scheme}://#{base_uri.host}:#{base_uri.port}#{base_uri.path.split('/')[0..-2].join('/')}#{current_path}")

      http = Net::HTTP.new(dir_uri.host, dir_uri.port)
      http.use_ssl = dir_uri.scheme == 'https'

      # Prova a creare la directory (MKCOL)
      http.send_request('MKCOL', dir_uri.path, '', {
        'Authorization' => "Basic #{Base64.strict_encode64("#{username}:#{password}")}"
      })
      # Ignora se la directory esiste già (405) o è stata creata con successo (201)
    end
  end
end
