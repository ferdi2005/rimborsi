require "test_helper"

class ElectronicInvoiceHelperTest < ActiveSupport::TestCase
  test "electronic_invoice? should return true for XML content types" do
    assert ElectronicInvoiceHelper.electronic_invoice?("application/xml")
    assert ElectronicInvoiceHelper.electronic_invoice?("text/xml")
    assert ElectronicInvoiceHelper.electronic_invoice?("application/pkcs7-mime")
    assert ElectronicInvoiceHelper.electronic_invoice?("application/x-pkcs7-mime")
  end

  test "electronic_invoice? should return false for non-XML content types" do
    assert_not ElectronicInvoiceHelper.electronic_invoice?("application/pdf")
    assert_not ElectronicInvoiceHelper.electronic_invoice?("image/jpeg")
    assert_not ElectronicInvoiceHelper.electronic_invoice?("text/plain")
  end

  test "generate_pdf_filename should replace XML extensions" do
    assert_equal "fattura_fattura.pdf", ElectronicInvoiceHelper.generate_pdf_filename("fattura.xml")
    assert_equal "fattura_fattura.pdf", ElectronicInvoiceHelper.generate_pdf_filename("fattura.XML")
    assert_equal "fattura_fattura.pdf", ElectronicInvoiceHelper.generate_pdf_filename("fattura.xml.p7m")
    assert_equal "fattura_fattura.pdf", ElectronicInvoiceHelper.generate_pdf_filename("fattura.XML.P7M")
  end

  test "generate_pdf_filename should handle files without XML extensions" do
    assert_equal "document.pdf_fattura.pdf", ElectronicInvoiceHelper.generate_pdf_filename("document.pdf")
    assert_equal "document_fattura.pdf", ElectronicInvoiceHelper.generate_pdf_filename("document")
  end

  test "parse_xml should handle empty or invalid XML" do
    result = ElectronicInvoiceHelper.send(:parse_xml, "")
    assert_equal({}, result)

    result = ElectronicInvoiceHelper.send(:parse_xml, "invalid xml")
    assert_equal({}, result)
  end

  test "parse_xml should extract basic invoice data from valid XML" do
    xml_content = <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <FatturaElettronica>
        <FatturaElettronicaHeader>
          <CedentePrestatore>
            <DatiAnagrafici>
              <IdFiscaleIVA>
                <IdPaese>IT</IdPaese>
                <IdCodice>12345678901</IdCodice>
              </IdFiscaleIVA>
              <Denominazione>Azienda Fornitrice S.r.l.</Denominazione>
            </DatiAnagrafici>
            <Sede>
              <Indirizzo>Via Roma 1</Indirizzo>
              <CAP>00100</CAP>
              <Comune>Roma</Comune>
              <Provincia>RM</Provincia>
              <Nazione>IT</Nazione>
            </Sede>
          </CedentePrestatore>
          <CessionarioCommittente>
            <DatiAnagrafici>
              <IdFiscaleIVA>
                <IdPaese>IT</IdPaese>
                <IdCodice>98765432101</IdCodice>
              </IdFiscaleIVA>
              <Denominazione>Cliente S.p.A.</Denominazione>
            </DatiAnagrafici>
            <Sede>
              <Indirizzo>Via Milano 2</Indirizzo>
              <CAP>20100</CAP>
              <Comune>Milano</Comune>
              <Provincia>MI</Provincia>
              <Nazione>IT</Nazione>
            </Sede>
          </CessionarioCommittente>
        </FatturaElettronicaHeader>
        <FatturaElettronicaBody>
          <DatiGenerali>
            <DatiGeneraliDocumento>
              <TipoDocumento>TD01</TipoDocumento>
              <Divisa>EUR</Divisa>
              <Data>2024-01-15</Data>
              <Numero>FAT001</Numero>
              <ImportoTotaleDocumento>122.00</ImportoTotaleDocumento>
            </DatiGeneraliDocumento>
          </DatiGenerali>
          <DatiBeniServizi>
            <DettaglioLinee>
              <NumeroLinea>1</NumeroLinea>
              <Descrizione>Servizio di consulenza</Descrizione>
              <Quantita>1.00</Quantita>
              <PrezzoUnitario>100.00</PrezzoUnitario>
              <PrezzoTotale>100.00</PrezzoTotale>
              <AliquotaIVA>22.00</AliquotaIVA>
            </DettaglioLinee>
            <DatiRiepilogo>
              <AliquotaIVA>22.00</AliquotaIVA>
              <ImponibileImporto>100.00</ImponibileImporto>
              <Imposta>22.00</Imposta>
            </DatiRiepilogo>
          </DatiBeniServizi>
        </FatturaElettronicaBody>
      </FatturaElettronica>
    XML

    result = ElectronicInvoiceHelper.send(:parse_xml, xml_content)

    # Verifica dati generali
    assert_equal "FAT001", result[:general][:number]
    assert_equal "2024-01-15", result[:general][:date]
    assert_equal "EUR", result[:general][:currency]
    assert_equal 122.0, result[:general][:total_amount]

    # Verifica fornitore
    assert_equal "IT12345678901", result[:supplier][:vat_number]
    assert_equal "Azienda Fornitrice S.r.l.", result[:supplier][:name]
    assert_includes result[:supplier][:address], "Via Roma 1"

    # Verifica cliente
    assert_equal "IT98765432101", result[:customer][:vat_number]
    assert_equal "Cliente S.p.A.", result[:customer][:name]
    assert_includes result[:customer][:address], "Via Milano 2"

    # Verifica righe
    assert_equal 1, result[:lines].length
    assert_equal "Servizio di consulenza", result[:lines].first[:description]
    assert_equal 100.0, result[:lines].first[:unit_price]

    # Verifica riepilogo IVA
    assert_equal 1, result[:vat_summary].length
    assert_equal 22.0, result[:vat_summary].first[:vat_rate]
    assert_equal 100.0, result[:vat_summary].first[:taxable_amount]
    assert_equal 22.0, result[:vat_summary].first[:vat_amount]
  end

  test "convert_to_pdf should generate PDF from XML" do
    xml_content = <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <FatturaElettronica>
        <FatturaElettronicaHeader>
          <CedentePrestatore>
            <DatiAnagrafici>
              <Denominazione>Test Company</Denominazione>
            </DatiAnagrafici>
          </CedentePrestatore>
        </FatturaElettronicaHeader>
        <FatturaElettronicaBody>
          <DatiGenerali>
            <DatiGeneraliDocumento>
              <Numero>TEST001</Numero>
              <Data>2024-01-01</Data>
              <ImportoTotaleDocumento>100.00</ImportoTotaleDocumento>
            </DatiGeneraliDocumento>
          </DatiGenerali>
        </FatturaElettronicaBody>
      </FatturaElettronica>
    XML

    pdf_content = ElectronicInvoiceHelper.convert_to_pdf(xml_content)

    assert_not_nil pdf_content
    assert pdf_content.length > 0

    # Verifica che sia un PDF valido (inizia con %PDF)
    assert pdf_content.start_with?("%PDF")
  end

  test "should regenerate PDF when attachment changes" do
    # Crea una spesa con fattura elettronica
    expense = Expense.create!(
      description: "Test expense",
      amount: 100.0,
      category: "Travel"
    )

    # Simula l'attachment di una fattura elettronica
    xml_content = <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <FatturaElettronica>
        <FatturaElettronicaBody>
          <DatiGenerali>
            <DatiGeneraliDocumento>
              <Numero>OLD001</Numero>
              <Data>2024-01-01</Data>
              <ImportoTotaleDocumento>100.00</ImportoTotaleDocumento>
            </DatiGeneraliDocumento>
          </DatiGenerali>
        </FatturaElettronicaBody>
      </FatturaElettronica>
    XML

    # Crea un file temporaneo per il primo XML
    temp_file = Tempfile.new([ "test_invoice", ".xml" ])
    temp_file.write(xml_content)
    temp_file.rewind

    # Allega il primo file
    expense.attachment.attach(
      io: temp_file,
      filename: "invoice_old.xml",
      content_type: "application/xml"
    )

    temp_file.close
    temp_file.unlink

    # Verifica che il PDF sia stato generato
    assert expense.has_invoice_pdf?, "PDF should be generated"

    old_pdf_filename = expense.pdf_attachment.filename.to_s

    # Ora modifica l'attachment con un nuovo XML
    new_xml_content = <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <FatturaElettronica>
        <FatturaElettronicaBody>
          <DatiGenerali>
            <DatiGeneraliDocumento>
              <Numero>NEW002</Numero>
              <Data>2024-02-01</Data>
              <ImportoTotaleDocumento>200.00</ImportoTotaleDocumento>
            </DatiGeneraliDocumento>
          </DatiGenerali>
        </FatturaElettronicaBody>
      </FatturaElettronica>
    XML

    # Crea un nuovo file temporaneo
    new_temp_file = Tempfile.new([ "test_invoice_new", ".xml" ])
    new_temp_file.write(new_xml_content)
    new_temp_file.rewind

    # Sostituisce l'attachment
    expense.attachment.attach(
      io: new_temp_file,
      filename: "invoice_new.xml",
      content_type: "application/xml"
    )

    new_temp_file.close
    new_temp_file.unlink

    # Verifica che il PDF sia stato rigenerato
    expense.reload
    assert expense.has_invoice_pdf?, "PDF should still be present after regeneration"

    new_pdf_filename = expense.pdf_attachment.filename.to_s
    assert_equal "invoice_new_fattura.pdf", new_pdf_filename, "PDF filename should be updated"
    assert_not_equal old_pdf_filename, new_pdf_filename, "PDF filename should have changed"
  end

  test "is_p7m_file? should correctly identify P7M files" do
    assert ElectronicInvoiceHelper.is_p7m_file?("application/pkcs7-mime")
    assert ElectronicInvoiceHelper.is_p7m_file?("application/x-pkcs7-mime")
    assert ElectronicInvoiceHelper.is_p7m_file?('application/x-pkcs7-mime; name="invoice.xml.p7m"')

    assert_not ElectronicInvoiceHelper.is_p7m_file?("application/xml")
    assert_not ElectronicInvoiceHelper.is_p7m_file?("text/xml")
    assert_not ElectronicInvoiceHelper.is_p7m_file?("application/pdf")
  end

  test "decrypt_p7m should handle various P7M formats" do
    # Test con contenuto XML diretto (fallback)
    xml_content = '<?xml version="1.0"?><FatturaElettronica><test>content</test></FatturaElettronica>'
    result = ElectronicInvoiceHelper.send(:decrypt_p7m, xml_content)
    assert result.include?("<?xml"), "Should extract XML content"

    # Test con contenuto non P7M (dovrebbe restituire il contenuto originale)
    non_p7m_content = "This is not a P7M file"
    result = ElectronicInvoiceHelper.send(:decrypt_p7m, non_p7m_content)
    assert_equal non_p7m_content, result
  end

  test "extract_xml_from_raw_content should find XML in binary data" do
    # Simula contenuto binario con XML incorporato
    binary_content = "\x00\x01\x02<?xml version=\"1.0\"?><FatturaElettronica><test>content</test></FatturaElettronica>\x03\x04"
    result = ElectronicInvoiceHelper.send(:extract_xml_from_raw_content, binary_content)

    assert result.start_with?("<?xml"), "Should start with XML declaration"
    assert result.end_with?("</FatturaElettronica>"), "Should end with closing tag"
  end

  test "convert_to_pdf should handle P7M files" do
    # Simula un contenuto P7M che contiene XML
    p7m_content = "-----BEGIN PKCS7-----\n<?xml version=\"1.0\"?><FatturaElettronica><test>content</test></FatturaElettronica>\n-----END PKCS7-----"

    # Non dovrebbe sollevare errori anche se la decrittazione fallisce
    assert_nothing_raised do
      ElectronicInvoiceHelper.convert_to_pdf(p7m_content, "application/pkcs7-mime")
    end
  end
end
