require "test_helper"

class ReimboursementTest < ActiveSupport::TestCase
  self.fixture_table_names = []
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

  test "role_name returns translated role" do
    reimboursement = Reimboursement.new(role: :volunteer)
    I18n.with_locale(:it) do
      assert_equal "Volontario", reimboursement.role_name
    end

    I18n.with_locale(:en) do
      assert_equal "Volunteer", reimboursement.role_name
    end
  end

  test "role_other is required for other and event_co_organizer" do
    reimboursement = Reimboursement.new(role: :other, role_other: nil)
    reimboursement.valid?
    assert reimboursement.errors[:role_other].any?

    reimboursement.role = :event_co_organizer
    reimboursement.valid?
    assert reimboursement.errors[:role_other].any?

    reimboursement.role_other = "Associazione XYZ, Roma, CF 12345678901"
    reimboursement.valid?
    assert_empty reimboursement.errors[:role_other]

    reimboursement.role = :volunteer
    reimboursement.role_other = nil
    reimboursement.valid?
    assert_empty reimboursement.errors[:role_other]
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
end
