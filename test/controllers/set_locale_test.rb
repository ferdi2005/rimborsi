require "test_helper"
require "ostruct"

# Verifies ApplicationController#set_locale uses the user's locale
# when present and falls back to I18n.default_locale otherwise.
class SetLocaleTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  class FakeController < ApplicationController
    skip_before_action :authenticate_user!, raise: false
    attr_accessor :stub_user, :stub_request
    def current_user; stub_user; end
    def request; stub_request; end
    def trigger; set_locale; end
  end

  setup do
    @ctrl = FakeController.new
    @ctrl.stub_request = ActionDispatch::TestRequest.create
  end

  teardown do
    I18n.locale = I18n.default_locale
  end

  test "uses user's locale when present" do
    @ctrl.stub_user = OpenStruct.new(locale: "it")
    @ctrl.trigger
    assert_equal :it, I18n.locale
  end

  test "detects browser locale when user is nil" do
    @ctrl.stub_user = nil
    @ctrl.stub_request.env["HTTP_ACCEPT_LANGUAGE"] = "it-IT,it;q=0.9,en;q=0.8"
    @ctrl.trigger
    assert_equal :it, I18n.locale
  end

  test "falls back to english when browser requests unsupported language" do
    @ctrl.stub_user = nil
    @ctrl.stub_request.env["HTTP_ACCEPT_LANGUAGE"] = "de-DE,de;q=0.9,fr;q=0.8"
    @ctrl.trigger
    assert_equal :en, I18n.locale
  end

  test "falls back to english when no accept-language header is present" do
    @ctrl.stub_user = nil
    @ctrl.stub_request.env.delete("HTTP_ACCEPT_LANGUAGE")
    @ctrl.trigger
    assert_equal :en, I18n.locale
  end
end
