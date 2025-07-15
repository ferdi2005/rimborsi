require "test_helper"

class ExpenseTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @fund = projects(:one)
    @reimboursement = reimboursements(:one)
  end

  test "should detect electronic invoice XML file" do
    expense = Expense.new(
      purpose: "Test expense",
      amount: 100.0,
      date: Date.current,
      fund: @fund,
      reimboursement: @reimboursement,
    )

    # Simula un file XML
    xml_content = create_sample_electronic_invoice_xml
    file = Tempfile.new([ "test_invoice", ".xml" ])
    file.write(xml_content)
    file.rewind

    expense.attachment.attach(
      io: file,
      filename: "fattura_elettronica.xml",
      content_type: "application/xml"
    )

    assert expense.electronic_invoice?, "Should detect XML electronic invoice"

    file.close
    file.unlink
  end

  test "should detect electronic invoice P7M file" do
    expense = Expense.new(
      purpose: "Test expense",
      amount: 100.0,
      date: Date.current,
      fund: @fund,
      reimboursement: @reimboursement,
    )

    # Simula un file P7M
    xml_content = create_sample_electronic_invoice_xml
    file = Tempfile.new([ "test_invoice", ".xml.p7m" ])
    file.write(xml_content)
    file.rewind

    expense.attachment.attach(
      io: file,
      filename: "fattura_elettronica.xml.p7m",
      content_type: "application/pkcs7-mime"
    )

    assert expense.electronic_invoice?, "Should detect P7M electronic invoice"

    file.close
    file.unlink
  end

  test "should not detect non-electronic invoice files" do
    expense = Expense.new(
      purpose: "Test expense",
      amount: 100.0,
      date: Date.current,
      fund: @fund,
      reimboursement: @reimboursement,
    )

    # Simula un file PDF normale
    file = Tempfile.new([ "test_document", ".pdf" ])
    file.write("Some PDF content")
    file.rewind

    expense.attachment.attach(
      io: file,
      filename: "document.pdf",
      content_type: "application/pdf"
    )

    assert_not expense.electronic_invoice?, "Should not detect PDF as electronic invoice"

    file.close
    file.unlink
  end

  private

  def create_sample_electronic_invoice_xml
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <p:FatturaElettronica>
        <FatturaElettronicaHeader>
          <DatiTrasmissione>
            <IdTrasmittente>
              <IdPaese>IT</IdPaese>
              <IdCodice>12345678901</IdCodice>
            </IdTrasmittente>
          </DatiTrasmissione>
          <CedentePrestatore>
            <DatiAnagrafici>
              <IdFiscaleIVA>
                <IdPaese>IT</IdPaese>
                <IdCodice>12345678901</IdCodice>
              </IdFiscaleIVA>
              <Denominazione>Fornitore Test S.r.l.</Denominazione>
            </DatiAnagrafici>
            <Sede>
              <Indirizzo>Via Test 123</Indirizzo>
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
                <IdCodice>98765432109</IdCodice>
              </IdFiscaleIVA>
              <Denominazione>Cliente Test S.r.l.</Denominazione>
            </DatiAnagrafici>
            <Sede>
              <Indirizzo>Via Cliente 456</Indirizzo>
              <CAP>00200</CAP>
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
              <Data>2025-01-01</Data>
              <Numero>001</Numero>
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
      </p:FatturaElettronica>
    XML
  end

  test "should process electronic invoice correctly" do
    expense = Expense.new(
      purpose: "Test expense with electronic invoice",
      amount: 100.0,
      date: Date.current,
      fund: @fund,
      reimboursement: @reimboursement,
    )

    # Crea un file XML con dati del fornitore
    xml_content = create_sample_electronic_invoice_xml
    file = Tempfile.new([ "test_invoice", ".xml" ])
    file.write(xml_content)
    file.rewind

    # Allega il file e salva l'expense
    expense.attachment.attach(
      io: file,
      filename: "fattura_elettronica.xml",
      content_type: "application/xml"
    )

    expense.save!

    file.close
    file.unlink
  end
end
