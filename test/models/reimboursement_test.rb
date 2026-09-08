require "test_helper"

class ReimboursementTest < ActiveSupport::TestCase
  setup do
    @reimboursement = reimboursements(:one)
    @fund = funds(:one)
  end

  test "role_translations returns translations for all roles" do
    I18n.with_locale(:it) do
      translations = Reimboursement.role_translations
      assert_equal "Volontario", translations["volunteer"]
      assert_equal "Altro", translations["other"]
    end

    I18n.with_locale(:en) do
      translations = Reimboursement.role_translations
      assert_equal "Volunteer", translations["volunteer"]
      assert_equal "Other", translations["other"]
    end
  end

  test "display_role returns translated role" do
    reimboursement = Reimboursement.new(role: :volunteer)
    I18n.with_locale(:it) do
      assert_equal "Volontario", reimboursement.display_role
    end

    I18n.with_locale(:en) do
      assert_equal "Volunteer", reimboursement.display_role
    end

    unspecified = Reimboursement.new(role: nil)
    I18n.with_locale(:it) do
      assert_equal "Non specificato", unspecified.display_role
    end
    I18n.with_locale(:en) do
      assert_equal "Not specified", unspecified.display_role
    end
  end

  test "payment_method_type and display_fund_name return translated text" do
    reimboursement = Reimboursement.new(bank_account: bank_accounts(:one))
    I18n.with_locale(:it) do
      assert_equal "conto bancario", reimboursement.payment_method_type
    end
    I18n.with_locale(:en) do
      assert_equal "Bank account", reimboursement.payment_method_type
    end

    without_account = Reimboursement.new(bank_account: nil)
    I18n.with_locale(:it) do
      assert_equal "nessuno", without_account.payment_method_type
      assert_equal "Non assegnato", without_account.display_fund_name
      assert_equal "Non assegnato", without_account.display_project_name
    end
    I18n.with_locale(:en) do
      assert_equal "None", without_account.payment_method_type
      assert_equal "Not assigned", without_account.display_fund_name
      assert_equal "Not assigned", without_account.display_project_name
    end
  end

  test "display_project_name and single_project? handle direct and historical expenses" do
    r = Reimboursement.new(project: "Wiki Loves Monuments")
    assert_equal "Wiki Loves Monuments", r.display_project_name
    assert r.single_project?

    r_history = Reimboursement.new(project: nil)
    r_history.expenses.build(project: "Progetto A", amount: 10, requested_amount: 10, purpose: "Test", date: Date.current)
    r_history.expenses.build(project: "Progetto B", amount: 20, requested_amount: 20, purpose: "Test", date: Date.current)
    assert_not r_history.single_project?
    assert_equal "Progetto A, Progetto B", r_history.display_project_name
  end

  test "validates payment method and expenses with i18n messages" do
    r = Reimboursement.new(bank_account: nil)
    I18n.with_locale(:it) do
      r.valid?
      assert_includes r.errors[:base], "deve essere selezionato un conto bancario"
      assert_includes r.errors[:base], "deve avere almeno una spesa"
    end

    r2 = Reimboursement.new(bank_account: nil)
    I18n.with_locale(:en) do
      r2.valid?
      assert_includes r2.errors[:base], "a bank account must be selected"
      assert_includes r2.errors[:base], "must have at least one expense"
    end
  end

  test "status_translations and status_name return translated status" do
    reimboursement = Reimboursement.new(status: :created)
    I18n.with_locale(:it) do
      assert_equal "Creato", reimboursement.status_name
    end

    I18n.with_locale(:en) do
      assert_equal "Created", reimboursement.status_name
    end
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

  test "generate_pdf genera correttamente il documento anche con spese e progetti" do
    assert_not_nil @reimboursement.generate_pdf
  end
end
