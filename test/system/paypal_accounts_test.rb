require "application_system_test_case"

class PaypalAccountsTest < ApplicationSystemTestCase
  setup do
    @paypal_account = paypal_accounts(:one)
  end

  test "visiting the index" do
    visit paypal_accounts_url
    assert_selector "h1", text: "Paypal accounts"
  end

  test "should create paypal account" do
    visit paypal_accounts_url
    click_on "New paypal account"

    check "Default" if @paypal_account.default
    fill_in "Email", with: @paypal_account.email
    fill_in "User", with: @paypal_account.user_id
    click_on "Create Paypal account"

    assert_text "Paypal account was successfully created"
    click_on "Back"
  end

  test "should update Paypal account" do
    visit paypal_account_url(@paypal_account)
    click_on "Edit this paypal account", match: :first

    check "Default" if @paypal_account.default
    fill_in "Email", with: @paypal_account.email
    fill_in "User", with: @paypal_account.user_id
    click_on "Update Paypal account"

    assert_text "Paypal account was successfully updated"
    click_on "Back"
  end

  test "should destroy Paypal account" do
    visit paypal_account_url(@paypal_account)
    click_on "Destroy this paypal account", match: :first

    assert_text "Paypal account was successfully destroyed"
  end
end
