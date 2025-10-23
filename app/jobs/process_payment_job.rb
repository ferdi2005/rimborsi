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

    # Se ci sono stati errori, marca il pagamento come in errore
    if failed_reimboursements.any?
      Rails.logger.error "Failed to process reimboursements: #{failed_reimboursements.join(', ')}"
      Rails.logger.error "Marking payment #{payment.id} as 'error' status"

      # Marca il pagamento in stato di errore (i rimborsi mantengono il loro stato)
      payment.mark_as_error!

      # Inserire eventuale notifica
    end
  end

  # private

  def process_reimboursement(reimboursement)
    # Genera il PDF per il rimborso utilizzando il metodo del modello
    pdf_content = reimboursement.generate_pdf

    # Carica il PDF e le ricevute su NextCloud
    upload_files_to_nextcloud(reimboursement, pdf_content)
  end

  def upload_files_to_nextcloud(reimboursement, pdf_content)
    require "net/http"
    require "uri"
    require "base64"

    nextcloud_url = ENV["NEXTCLOUD_WEBDAV_URL"]
    username = ENV["NEXTCLOUD_USERNAME"]
    password = ENV["NEXTCLOUD_PASSWORD"]
    admin_folder = ENV["CARTELLA_AMMINISTRAZIONE"]

    raise "NextCloud configuration missing" if [ nextcloud_url, username, password, admin_folder ].any?(&:blank?)

    # Costruisci il path di destinazione con cartella data
    year_folder = Date.current.strftime("%Y")
    date_folder = Date.current.strftime("%m")

    base_path = "#{admin_folder}/#{year_folder}/#{date_folder}"

    # Crea tutte le directory necessarie
    base_uri = URI(nextcloud_url)
    ensure_directory_exists(base_uri, username, password, base_path)

    filename = "rimborso#{reimboursement.id}_#{reimboursement.user.surname}#{reimboursement.user.name}_#{Date.current.strftime("%Y%m%d")}".gsub(" ", "")

    # Carica il PDF del rimborso
    pdf_path = "#{base_path}/#{filename}.pdf"
    upload_file_to_nextcloud(nextcloud_url, pdf_path, pdf_content, "application/pdf", username, password)

    Rails.logger.info "Successfully uploaded PDF for reimboursement #{reimboursement.id} to #{pdf_path}"

    # Carica solo i file XML delle fatture elettroniche
    uploaded_invoices = 0
    reimboursement.expenses.each do |expense|
      if expense.electronic_invoice? && expense.attachment.attached?
        begin
          # Scarica il file XML della fattura elettronica
          attachment_content = expense.attachment.download

          # Determina il tipo di contenuto
          content_type = expense.attachment.content_type || "application/xml"

          # Costruisci il nome del file per la fattura elettronica
          fattura_elettronica_name = "rimborso#{reimboursement.id}_#{reimboursement.user.surname}#{reimboursement.user.name}_#{Date.current.strftime("%Y%m%d")}_fattura#{expense.id}".gsub(" ", "")

          # Mantieni l'estensione originale del file
          original_extension = File.extname(expense.attachment.filename.to_s)
          invoice_filename = "#{fattura_elettronica_name}#{original_extension}"
          invoice_path = "#{base_path}/#{invoice_filename}"

          # Carica la fattura elettronica
          upload_file_to_nextcloud(nextcloud_url, invoice_path, attachment_content, content_type, username, password)

          uploaded_invoices += 1
          Rails.logger.info "Successfully uploaded electronic invoice for expense #{expense.id}: #{invoice_filename}"

        rescue StandardError => e
          Rails.logger.error "Failed to upload electronic invoice for expense #{expense.id}: #{e.message}"
          # Continua con le altre fatture anche se una fallisce
        end
      end
    end

    Rails.logger.info "Successfully uploaded #{uploaded_invoices} electronic invoices for reimboursement #{reimboursement.id}"
  end

  def upload_file_to_nextcloud(nextcloud_url, remote_path, content, content_type, username, password)
    webdav_url = "#{nextcloud_url}/#{remote_path}"
    uri = URI(webdav_url)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == "https"

    request = Net::HTTP::Put.new(uri)
    request.basic_auth(username, password)
    request["Content-Type"] = content_type
    request.body = content

    response = http.request(request)

    unless response.code.to_i.between?(200, 299)
      raise "Failed to upload file to NextCloud: #{response.code} #{response.message} - Path: #{remote_path}"
    end
  end

def ensure_directory_exists(base_uri, username, password, directory_path)
  path_parts = directory_path.split("/")
  current_path = ""

  path_parts.each do |part|
    next if part.blank?

    current_path += "/#{part}"

    # Costruisci l'URI corretto per WebDAV
    dir_path = "#{base_uri.path.chomp('/')}#{current_path}"
    dir_uri = URI("#{base_uri.scheme}://#{base_uri.host}:#{base_uri.port}#{dir_path}")

    http = Net::HTTP.new(dir_uri.host, dir_uri.port)
    http.use_ssl = dir_uri.scheme == "https"

    # Prima verifica se la directory esiste già
    head_request = Net::HTTP::Head.new(dir_uri.path)
    head_request.basic_auth(username, password)
    head_response = http.request(head_request)

    # Se la directory non esiste (404), creala
    if head_response.code == "404"
      mkcol_request = Net::HTTP::Mkcol.new(dir_uri.path)
      mkcol_request.basic_auth(username, password)

      response = http.request(mkcol_request)

      Rails.logger.info "MKCOL response for #{dir_path}: #{response.code} #{response.message}"

      # 201 = creata, 405 = esiste già, altri codici = errore
      unless [ "201", "405" ].include?(response.code)
        Rails.logger.error "Failed to create directory #{dir_path}: #{response.code} #{response.message}"
        Rails.logger.error "Response body: #{response.body}"
      end
    end
  end
end
end
