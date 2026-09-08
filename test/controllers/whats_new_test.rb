require "test_helper"

class WhatsNewTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    @user.update_column(:seen_whats_new, false)
  end

  test "unauthenticated user cannot dismiss whats new" do
    patch dismiss_whats_new_url, as: :json
    assert_response :unauthorized
  end

  test "authenticated user can dismiss whats new" do
    sign_in @user
    assert_not @user.seen_whats_new?

    patch dismiss_whats_new_url, as: :json
    assert_response :ok

    @user.reload
    assert @user.seen_whats_new?
  end
end
