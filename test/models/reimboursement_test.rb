require "test_helper"

class ReimboursementTest < ActiveSupport::TestCase
  setup do
    @reimboursement = reimboursements(:one)
    @fund = funds(:one)
  end

  test "richiede la presenza del progetto" do
    @reimboursement.project = nil
    assert_not @reimboursement.valid?
    assert_includes @reimboursement.errors[:project], "non può essere vuoto"
  end

  test "richiede la presenza del ruolo" do
    @reimboursement.role = nil
    assert_not @reimboursement.valid?
    assert_includes @reimboursement.errors[:role], "non può essere vuoto"
  end

  test "richiede la presenza del fondo per i nuovi rimborsi" do
    new_reimboursement = Reimboursement.new(
      user: users(:one),
      bank_account: bank_accounts(:one),
      project: "Progetto test"
    )
    assert_not new_reimboursement.valid?
    assert_includes new_reimboursement.errors[:fund], "non può essere vuoto"
  end

  test "display_fund_name restituisce il nome del fondo associato" do
    assert_equal @fund.name, @reimboursement.display_fund_name
  end

  test "single_fund? restituisce true se il rimborso ha un solo fondo" do
    assert @reimboursement.single_fund?
  end

  test "causale_bonifico include id, fondo e progetto rispettando il limite di 140 caratteri" do
    causale = @reimboursement.causale_bonifico
    assert_includes causale, "Rimborso spese n. #{@reimboursement.id}"
    assert_includes causale, @fund.name
    assert_includes causale, @reimboursement.project
    assert causale.length <= 140
  end

  test "causale_bonifico tronca correttamente testi lunghi a 140 caratteri" do
    @reimboursement.project = "A" * 200
    causale = @reimboursement.causale_bonifico
    assert_equal 140, causale.length
  end

  test "sincronizza automaticamente fund_id sulle nuove spese create con il rimborso" do
    expense = @reimboursement.expenses.build(
      purpose: "Spesa test",
      date: Date.current,
      amount: 10.0,
      requested_amount: 10.0,
      car: false
    )
    expense.attachment.attach(
      io: StringIO.new("%PDF-1.4 dummy pdf"),
      filename: "test.pdf",
      content_type: "application/pdf"
    )
    assert @reimboursement.save
    assert_equal @reimboursement.fund_id, expense.fund_id
  end

  test "display_role restituisce il ruolo tradotto semplice se non co-organizzatore o altro" do
    @reimboursement.role = :volunteer
    @reimboursement.role_other = nil
    assert_equal "Volontario", @reimboursement.display_role
  end

  test "display_role include la specifica role_other per co-organizzatore e altro" do
    @reimboursement.role = :event_co_organizer
    @reimboursement.role_other = "Associazione test, Roma, CF 12345678901"
    assert_includes @reimboursement.display_role, "Associazione test, Roma, CF 12345678901"

    @reimboursement.role = :other
    @reimboursement.role_other = "Consulente esterno"
    assert_equal "Altro (Consulente esterno)", @reimboursement.display_role
  end

  test "richiede la compilazione di role_other per altro e co-organizzatore" do
    @reimboursement.role = :other
    @reimboursement.role_other = nil
    assert_not @reimboursement.valid?
    assert @reimboursement.errors[:role_other].any?

    @reimboursement.role = :event_co_organizer
    @reimboursement.role_other = nil
    assert_not @reimboursement.valid?
    assert @reimboursement.errors[:role_other].any?

    @reimboursement.role_other = "Specifica valida"
    assert @reimboursement.valid?
  end
end
