require "test_helper"

class ReimboursementTest < ActiveSupport::TestCase
  # Le fixture esistenti sono obsolete (colonne rinominate dalle migrazioni successive);
  # questa classe costruisce i record inline e non ne ha bisogno.
  self.fixture_table_names = []

  def build_user
    User.create!(
      name: "Mario",
      surname: "Rossi",
      email: "mario.rossi.#{SecureRandom.hex(4)}@example.com",
      fiscal_code: "RSSMRA80A01H501U#{SecureRandom.hex(2)}",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  test "draft saves without bank account or expenses" do
    user = build_user
    r = Reimboursement.new(user: user, status: :draft)
    assert r.save, "Expected draft to save without bank_account/expenses, got: #{r.errors.full_messages}"
  end

  test "transitioning a draft to created re-applies validations" do
    user = build_user
    r = Reimboursement.create!(user: user, status: :draft)
    r.status = :created
    refute r.save
    assert_includes r.errors[:base], "Deve essere selezionato un conto bancario"
    assert_includes r.errors[:base], "Deve avere almeno una spesa"
  end

  test "non-admin owner can edit drafts" do
    user = build_user
    r = Reimboursement.create!(user: user, status: :draft)
    user.define_singleton_method(:admin?) { false }
    assert r.can_be_edited_by?(user)
  end

  test "draft is not approvable" do
    user = build_user
    r = Reimboursement.create!(user: user, status: :draft)
    refute r.can_be_approved?
  end
end
