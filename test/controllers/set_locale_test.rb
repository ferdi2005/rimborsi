require "test_helper"
require "ostruct"

# Verifies ApplicationController#set_locale uses the user's locale
# when present and falls back to I18n.default_locale otherwise.
class SetLocaleTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  class FakeController < ApplicationController
    skip_before_action :authenticate_user!, raise: false
    attr_accessor :stub_user
    def current_user; stub_user; end
    def trigger; set_locale; end
  end

  setup { @ctrl = FakeController.new }

  test "uses user's locale when present" do
    @ctrl.stub_user = OpenStruct.new(locale: "en")
    @ctrl.trigger
    assert_equal :en, I18n.locale
  ensure
    I18n.locale = I18n.default_locale
  end

  test "falls back to default when user is nil" do
    @ctrl.stub_user = nil
    I18n.locale = :en  # ensure it changes
    @ctrl.trigger
    assert_equal I18n.default_locale, I18n.locale
  end

  test "falls back to default when user has nil locale" do
    @ctrl.stub_user = OpenStruct.new(locale: nil)
    I18n.locale = :en
    @ctrl.trigger
    assert_equal I18n.default_locale, I18n.locale
  end
end
