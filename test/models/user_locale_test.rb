require "test_helper"

class UserLocaleTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  def build_user(overrides = {})
    User.new({
      email: "loc#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      password_confirmation: "password123",
      name: "Mario",
      surname: "Rossi",
      fiscal_code: "RSSMRA80A01H501#{('A'..'Z').to_a.sample}"
    }.merge(overrides))
  end

  # The locale column has a DB default of 'it', so even User.new without
  # an explicit locale comes back with "it". The before_create callback
  # in user.rb is essentially a backstop for the same behavior.
  test "default locale is 'it' when not explicitly set" do
    user = build_user
    user.save!
    assert_equal "it", user.locale
  end

  test "explicit locale is preserved on create" do
    user = build_user(locale: "en")
    user.save!
    assert_equal "en", user.locale
  end

  test "rejects locales other than it/en" do
    user = build_user(locale: "fr")
    refute user.valid?
    assert_includes user.errors[:locale], "deve essere 'it' o 'en'"
  end

  test "accepts both supported locales" do
    %w[it en].each do |loc|
      assert build_user(locale: loc).valid?, "expected #{loc} to be valid"
    end
  end
end
