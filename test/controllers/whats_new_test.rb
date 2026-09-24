require "test_helper"

class WhatsNewTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    @user.update_column(:seen_whats_new_version, nil)
  end

  test "unauthenticated user cannot dismiss whats new" do
    patch dismiss_whats_new_url, as: :json
    assert_response :unauthorized
  end

  test "authenticated user can dismiss whats new" do
    sign_in @user
    assert_not @user.seen_latest_whats_new?

    patch dismiss_whats_new_url, params: { version: Rimborsi::VERSION }, as: :json
    assert_response :ok

    @user.reload
    assert @user.seen_latest_whats_new?
    assert_equal Rimborsi::VERSION, @user.seen_whats_new_version
  end

  test "user with older version is prompted again for latest whats new" do
    @user.update_column(:seen_whats_new_version, "0.9")
    assert_not @user.seen_latest_whats_new?

    @user.dismiss_whats_new!(Rimborsi::VERSION)
    assert @user.seen_latest_whats_new?
  end
end
