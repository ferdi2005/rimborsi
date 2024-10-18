require "test_helper"

class PaypalAccountsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @paypal_account = paypal_accounts(:one)
  end

  test "should get index" do
    get paypal_accounts_url
    assert_response :success
  end

  test "should get new" do
    get new_paypal_account_url
    assert_response :success
  end

  test "should create paypal_account" do
    assert_difference("PaypalAccount.count") do
      post paypal_accounts_url, params: { paypal_account: { default: @paypal_account.default, email: @paypal_account.email, user_id: @paypal_account.user_id } }
    end

    assert_redirected_to paypal_account_url(PaypalAccount.last)
  end

  test "should show paypal_account" do
    get paypal_account_url(@paypal_account)
    assert_response :success
  end

  test "should get edit" do
    get edit_paypal_account_url(@paypal_account)
    assert_response :success
  end

  test "should update paypal_account" do
    patch paypal_account_url(@paypal_account), params: { paypal_account: { default: @paypal_account.default, email: @paypal_account.email, user_id: @paypal_account.user_id } }
    assert_redirected_to paypal_account_url(@paypal_account)
  end

  test "should destroy paypal_account" do
    assert_difference("PaypalAccount.count", -1) do
      delete paypal_account_url(@paypal_account)
    end

    assert_redirected_to paypal_accounts_url
  end
end
