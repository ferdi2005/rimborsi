module ElectronicInvoiceHelper
  # Converte una fattura elettronica XML in PDF
  def self.convert_to_pdf(file_content, content_type = nil)
    # Se è un file P7M, decrittalo prima
    xml_content = if is_p7m_file?(content_type)
      decrypt_p7m(file_content)
    else
      file_content
    end

    # Parse dell'XML
    parsed_invoice = parse_xml(xml_content)

    # Genera il PDF
    pdf_content = generate_pdf(parsed_invoice)

    pdf_content
  end

  # Verifica se il file è un P7M
  def self.is_p7m_file?(content_type)
    [ "application/pkcs7-mime", "application/x-pkcs7-mime" ].include?(content_type) ||
    content_type&.include?("p7m")
  end

  # Decrittazione file P7M
  def self.decrypt_p7m(p7m_content)
    require "openssl"
    require "base64"

    begin
      Rails.logger.info "Tentativo di decrittazione file P7M (#{p7m_content.length} bytes)"

      # Strategia 1: Prova con PKCS7 direttamente
      result = extract_with_pkcs7(p7m_content)
      return result if result && !result.empty? && result.include?("<?xml")

      # Strategia 2: Prova interpretando come S/MIME
      result = extract_with_smime(p7m_content)
      return result if result && !result.empty? && result.include?("<?xml")

      # Strategia 3: Prova con diversi encoding
      result = extract_with_different_encodings(p7m_content)
      return result if result && !result.empty? && result.include?("<?xml")

      # Strategia 4: Cerca XML direttamente nel contenuto raw
      result = extract_xml_from_raw_content(p7m_content)
      return result if result && !result.empty?

      Rails.logger.warn "Impossibile decrittare il file P7M con nessuna strategia, restituisco il contenuto originale"
      p7m_content
    rescue => e
      Rails.logger.error "Errore durante la decrittazione P7M: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      # In caso di errore, restituisce il contenuto originale
      p7m_content
    end
  end

  # Estrazione usando PKCS7
  def self.extract_with_pkcs7(p7m_content)
    # Supporta BER indefinite-length convertendo prima in DER
    begin
      asn1_objs = OpenSSL::ASN1.decode_all(p7m_content)
      if asn1_objs && asn1_objs.first
        p7m_content = asn1_objs.first.to_der
        Rails.logger.info "BER->DER: convertito indefinite-length prima di PKCS7"
      end
    rescue => e
      Rails.logger.debug "BER->DER fallback failed: #{e.message}"
    end
    begin
      # Prova prima con il contenuto così com'è
      pkcs7 = OpenSSL::PKCS7.new(p7m_content)

      if pkcs7.type == "signed"
        content = pkcs7.data
        Rails.logger.info "PKCS7 decrittato con successo (tipo: signed)"
        return content if content && content.include?("<?xml")
      elsif pkcs7.type == "enveloped"
        Rails.logger.info "File P7M è di tipo enveloped (crittografato), necessaria chiave privata"
      end
    rescue OpenSSL::PKCS7::PKCS7Error => e
      Rails.logger.debug "Errore PKCS7 diretto: #{e.message}"

      # Strategia 1a: tenta di decodificare BER indefinite-length con ASN1.decode_all
      begin
        Rails.logger.info "Tentativo di decodifica BER(indefinite) con ASN1.decode_all"
        asn1_objects = OpenSSL::ASN1.decode_all(p7m_content)
        if asn1_objects && asn1_objects.first
          der_data = asn1_objects.first.to_der
          pkcs7 = OpenSSL::PKCS7.new(der_data)
          if pkcs7.type == "signed"
            content = pkcs7.data
            Rails.logger.info "PKCS7 BER->DER decrittato con successo"
            return content if content && content.include?("<?xml")
          end
        end
      rescue => ber_e
        Rails.logger.debug "Errore BER->DER extraction: #{ber_e.message}"
      end
    end

    # Prova con formato DER se non funziona direttamente
    begin
      # Se il contenuto inizia con caratteri stampabili, potrebbe essere in base64
      if p7m_content.start_with?("-----BEGIN")
        # Rimuovi header e footer PEM e decodifica base64
        content_lines = p7m_content.lines
        content_lines = content_lines.reject { |line| line.start_with?("-----") }
        base64_content = content_lines.join.gsub(/\s/, "")
        binary_content = Base64.decode64(base64_content)

        pkcs7 = OpenSSL::PKCS7.new(binary_content)
        if pkcs7.type == "signed"
          content = pkcs7.data
          Rails.logger.info "PKCS7 decrittato con successo da formato PEM"
          return content if content && content.include?("<?xml")
        end
      end
    rescue => e
      Rails.logger.debug "Errore PKCS7 con formato PEM: #{e.message}"
    end

    nil
  end

  # Estrazione usando S/MIME
  def self.extract_with_smime(p7m_content)
    begin
      # Prova a interpretare come messaggio S/MIME
      if p7m_content.include?("Content-Type:") || p7m_content.start_with?("MIME-Version:")
        # È un messaggio S/MIME completo
        pkcs7 = OpenSSL::PKCS7.read_smime(p7m_content)
        if pkcs7
          content = pkcs7.data
          Rails.logger.info "S/MIME decrittato con successo"
          return content if content && content.include?("<?xml")
        end
      end
    rescue => e
      Rails.logger.debug "Errore S/MIME: #{e.message}"
    end

    nil
  end

  # Prova con diversi encoding
  def self.extract_with_different_encodings(p7m_content)
    encodings = [ "UTF-8", "ISO-8859-1", "ASCII-8BIT" ]

    encodings.each do |encoding|
      begin
        content = p7m_content.force_encoding(encoding)

        # Cerca pattern XML
        if content.include?("<?xml") && content.include?("</FatturaElettronica>")
          start_pos = content.index("<?xml")
          end_pos = content.rindex("</FatturaElettronica>") + "</FatturaElettronica>".length
          result = content[start_pos...end_pos]

          # Verifica che sia XML valido
          if result.length > 50 # Almeno una dimensione minima ragionevole
            Rails.logger.info "XML estratto con encoding #{encoding}"
            return result
          end
        end
      rescue => e
        Rails.logger.debug "Errore con encoding #{encoding}: #{e.message}"
      end
    end

    nil
  end

  # Estrazione XML dal contenuto raw
  def self.extract_xml_from_raw_content(p7m_content)
    begin
      data = p7m_content.dup.force_encoding("ASCII-8BIT")
      # Regex per start/end tag di FatturaElettronica con namespace opzionale
      start_regex = /<(?:(?:\w+:)?FatturaElettronica)\b/
      end_regex = /<\/(?:(?:\w+:)?FatturaElettronica)>/
      start_match = data.match(start_regex)
      end_match = data.match(end_regex)
      if start_match && end_match
        start_pos = start_match.begin(0)
        end_pos = end_match.end(0)
        result = data[start_pos...end_pos]
        # Rimuovi eventuali caratteri non stampabili ai bordi e caratteri di controllo
        result = result.gsub(/\A[^<]*/, "").gsub(/[^>]*\z/, "")
        result = result.gsub(/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/, "")
        Rails.logger.info "Raw regex extraction: trovata FatturaElettronica, pulita da caratteri binari"
        return result if result.length > 100
      end
      # Fallback con tag statici
      start_tags = [ "<?xml", "<ns3:FatturaElettronica", "<p:FatturaElettronica" ]
      close_tags = [ "</FatturaElettronica>", "</ns3:FatturaElettronica>", "</p:FatturaElettronica>" ]
      start_tag = start_tags.find { |tag| data.include?(tag) }
      end_tag = close_tags.find { |tag| data.include?(tag) }
      if start_tag && end_tag
        start_pos = data.index(start_tag)
        end_pos = data.rindex(end_tag) + end_tag.length
        result = data[start_pos...end_pos]
        result = result.gsub(/\A[^<]*/, "").gsub(/[^>]*\z/, "")
        result = result.gsub(/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/, "")
        Rails.logger.info "Raw fallback extraction: XML pulito da caratteri binari"
        return result if result.length > 100
      end
    rescue => e
      Rails.logger.debug "Errore estrazione raw: #{e.message}"
    end
    nil
  end

  # Metodo alternativo per estrarre con Ruby OpenSSL (deprecato - ora integrato in extract_with_pkcs7)
  # def self.extract_with_ruby_openssl(p7m_content)
  #   # Metodo rimosso - logica integrata direttamente in decrypt_p7m
  # end

  # Verifica se un file è una fattura elettronica basandosi su content type
  def self.electronic_invoice?(content_type)
    [ "application/xml", "text/xml", "application/pkcs7-mime", "application/x-pkcs7-mime" ].include?(content_type)
  end

  # Genera il nome del file PDF basandosi sul nome originale
  def self.generate_pdf_filename(original_filename)
    original_filename.to_s.gsub(/\.(xml|xml\.p7m)$/i, "_fattura.pdf")
  end

  private

  # Parsing della fattura elettronica XML
  def self.parse_xml(xml_content)
    require "nokogiri"

    doc = Nokogiri::XML(xml_content)
    doc.remove_namespaces! # Rimuove i namespace per semplificare il parsing

    invoice_data = {}

    # Estrazione dati del fornitore
    supplier_node = doc.at("CedentePrestatore//DatiAnagrafici")
    if supplier_node
      invoice_data[:supplier] = {
        vat_number: extract_vat_number(doc, "CedentePrestatore"),
        name: extract_name(supplier_node),
        address: extract_address(doc.at("CedentePrestatore//Sede"))
      }
    end

    # Estrazione dati del cliente
    customer_node = doc.at("CessionarioCommittente//DatiAnagrafici")
    if customer_node
      invoice_data[:customer] = {
        vat_number: extract_vat_number(doc, "CessionarioCommittente"),
        name: extract_name(customer_node),
        address: extract_address(doc.at("CessionarioCommittente//Sede"))
      }
    end

    # Estrazione dati generali della fattura
    general_data = doc.at("DatiGeneraliDocumento")
    if general_data
      invoice_data[:general] = {
        number: general_data.at("Numero")&.text,
        date: general_data.at("Data")&.text,
        currency: general_data.at("Divisa")&.text || "EUR",
        total_amount: general_data.at("ImportoTotaleDocumento")&.text&.to_f || 0
      }
    end

    # Estrazione righe della fattura
    invoice_data[:lines] = extract_invoice_lines(doc)

    # Estrazione riepilogo IVA
    invoice_data[:vat_summary] = extract_vat_summary(doc)

    invoice_data
  rescue => e
    Rails.logger.error "Errore nel parsing XML della fattura: #{e.message}"
    {}
  end

  # Genera il PDF della fattura
  def self.generate_pdf(invoice_data)
    Prawn::Document.new(page_size: "A4", margin: 40) do |pdf|
      # Usa il font standard Helvetica che supporta caratteri base
      pdf.font "Helvetica"

      # Header
      generate_header(pdf)

      # Informazioni generali
      generate_general_info(pdf, invoice_data[:general]) if invoice_data[:general]

      # Dati fornitore
      generate_supplier_info(pdf, invoice_data[:supplier]) if invoice_data[:supplier]

      # Dati cliente
      generate_customer_info(pdf, invoice_data[:customer]) if invoice_data[:customer]

      # Righe della fattura
      generate_invoice_lines(pdf, invoice_data[:lines]) if invoice_data[:lines]&.any?

      # Riepilogo IVA
      generate_vat_summary(pdf, invoice_data[:vat_summary]) if invoice_data[:vat_summary]&.any?

      # Totale
      generate_total(pdf, invoice_data[:general]) if invoice_data[:general]&.dig(:total_amount)
    end.render
  end

  # Estrae il numero di partita IVA
  def self.extract_vat_number(doc, section)
    country = doc.at("#{section}//IdPaese")&.text.to_s
    code = doc.at("#{section}//IdCodice")&.text.to_s
    "#{country}#{code}"
  end

  # Estrae il nome (denominazione o nome/cognome)
  def self.extract_name(node)
    return node.at("Denominazione")&.text if node.at("Denominazione")

    nome = node.at("Nome")&.text
    cognome = node.at("Cognome")&.text
    "#{nome} #{cognome}".strip if nome || cognome
  end

  # Estrae l'indirizzo completo
  def self.extract_address(address_node)
    return "" unless address_node

    address_parts = []
    address_parts << address_node.at("Indirizzo")&.text
    address_parts << address_node.at("CAP")&.text
    address_parts << address_node.at("Comune")&.text
    address_parts << address_node.at("Provincia")&.text
    address_parts << address_node.at("Nazione")&.text

    address_parts.compact.reject(&:blank?).join(", ")
  end

  # Estrae le righe della fattura
  def self.extract_invoice_lines(doc)
    lines = []
    doc.xpath("//DettaglioLinee").each do |line|
      lines << {
        description: line.at("Descrizione")&.text,
        quantity: line.at("Quantita")&.text&.to_f || 1,
        unit_price: line.at("PrezzoUnitario")&.text&.to_f || 0,
        total: line.at("PrezzoTotale")&.text&.to_f || 0,
        vat_rate: line.at("AliquotaIVA")&.text&.to_f || 0
      }
    end
    lines
  end

  # Estrae il riepilogo IVA
  def self.extract_vat_summary(doc)
    summary = []
    doc.xpath("//DatiRiepilogo").each do |vat_summary|
      summary << {
        vat_rate: vat_summary.at("AliquotaIVA")&.text&.to_f || 0,
        taxable_amount: vat_summary.at("ImponibileImporto")&.text&.to_f || 0,
        vat_amount: vat_summary.at("Imposta")&.text&.to_f || 0
      }
    end
    summary
  end

  # Genera l'header del PDF
  def self.generate_header(pdf)
    pdf.text "FATTURA ELETTRONICA", size: 20, style: :bold, align: :center
    pdf.move_down 30
  end

  # Genera le informazioni generali
  def self.generate_general_info(pdf, general_data)
    pdf.text "Numero: #{general_data[:number]}", size: 12, style: :bold
    pdf.text "Data: #{general_data[:date]}", size: 12
    pdf.text "Valuta: #{general_data[:currency]}", size: 12
    pdf.move_down 20
  end

  # Genera le informazioni del fornitore
  def self.generate_supplier_info(pdf, supplier_data)
    pdf.text "FORNITORE", size: 14, style: :bold
    pdf.text "#{supplier_data[:name]}", size: 11
    pdf.text "P.IVA: #{supplier_data[:vat_number]}", size: 10
    pdf.text "#{supplier_data[:address]}", size: 10
    pdf.move_down 15
  end

  # Genera le informazioni del cliente
  def self.generate_customer_info(pdf, customer_data)
    pdf.text "CLIENTE", size: 14, style: :bold
    pdf.text "#{customer_data[:name]}", size: 11
    pdf.text "P.IVA: #{customer_data[:vat_number]}", size: 10
    pdf.text "#{customer_data[:address]}", size: 10
    pdf.move_down 20
  end

  # Genera le righe della fattura
  def self.generate_invoice_lines(pdf, lines)
    return unless lines&.any?

    pdf.text "DETTAGLIO", size: 14, style: :bold
    pdf.move_down 10

    # Tabella delle righe
    table_data = [ [ "Descrizione", "Qta", "Prezzo Unit.", "Totale", "IVA%" ] ]

    lines.each do |line|
      table_data << [
        line[:description] || "",
        line[:quantity]&.to_s || "1",
        "€ #{sprintf('%.2f', line[:unit_price] || 0)}",
        "€ #{sprintf('%.2f', line[:total] || 0)}",
        "#{line[:vat_rate] || 0}%"
      ]
    end

    # Calcola la larghezza disponibile e distribuisci le colonne
    available_width = pdf.bounds.width
    pdf.table(table_data, header: true, width: available_width) do
      row(0).font_style = :bold
      columns(1..4).align = :right
      # Distribuzione proporzionale: Descrizione più larga, altre più piccole
      self.column_widths = {
        0 => available_width * 0.45,  # 45% per descrizione
        1 => available_width * 0.10,  # 10% per quantità
        2 => available_width * 0.15,  # 15% per prezzo unitario
        3 => available_width * 0.15,  # 15% per totale
        4 => available_width * 0.15   # 15% per IVA
      }
    end

    pdf.move_down 20
  end

  # Genera il riepilogo IVA
  def self.generate_vat_summary(pdf, vat_summary)
    return unless vat_summary&.any?

    pdf.text "RIEPILOGO IVA", size: 14, style: :bold
    pdf.move_down 10

    vat_table_data = [ [ "Aliquota", "Imponibile", "Imposta" ] ]

    vat_summary.each do |vat|
      vat_table_data << [
        "#{vat[:vat_rate]}%",
        "€ #{sprintf('%.2f', vat[:taxable_amount])}",
        "€ #{sprintf('%.2f', vat[:vat_amount])}"
      ]
    end

    # Calcola larghezza per tabella del riepilogo (più piccola, a destra)
    vat_table_width = pdf.bounds.width * 0.6  # 60% della larghezza disponibile
    pdf.table(vat_table_data, header: true, width: vat_table_width) do
      row(0).font_style = :bold
      columns(1..2).align = :right
      self.position = :right
      # Distribuisci equamente le 3 colonne
      self.column_widths = {
        0 => vat_table_width * 0.33,
        1 => vat_table_width * 0.33,
        2 => vat_table_width * 0.34
      }
    end

    pdf.move_down 15
  end

  # Genera il totale
  def self.generate_total(pdf, general_data)
    pdf.text "TOTALE FATTURA: € #{sprintf('%.2f', general_data[:total_amount])}",
             size: 16, style: :bold, align: :right
  end
end
