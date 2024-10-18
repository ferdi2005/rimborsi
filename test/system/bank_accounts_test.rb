require "application_system_test_case"

class BankAccountsTest < ApplicationSystemTestCase
  setup do
    @bank_account = bank_accounts(:one)
  end

  test "visiting the index" do
    visit bank_accounts_url
    assert_selector "h1", text: "Bank accounts"
  end

  test "should create bank account" do
    visit bank_accounts_url
    click_on "New bank account"

    fill_in "Address", with: @bank_account.address
    fill_in "Cap", with: @bank_account.cap
    check "Default" if @bank_account.default
    fill_in "Fiscal code", with: @bank_account.fiscal_code
    fill_in "Iban", with: @bank_account.iban
    fill_in "Owner", with: @bank_account.owner
    fill_in "Town", with: @bank_account.town
    fill_in "User", with: @bank_account.user_id
    click_on "Create Bank account"

    assert_text "Bank account was successfully created"
    click_on "Back"
  end

  test "should update Bank account" do
    visit bank_account_url(@bank_account)
    click_on "Edit this bank account", match: :first

    fill_in "Address", with: @bank_account.address
    fill_in "Cap", with: @bank_account.cap
    check "Default" if @bank_account.default
    fill_in "Fiscal code", with: @bank_account.fiscal_code
    fill_in "Iban", with: @bank_account.iban
    fill_in "Owner", with: @bank_account.owner
    fill_in "Town", with: @bank_account.town
    fill_in "User", with: @bank_account.user_id
    click_on "Update Bank account"

    assert_text "Bank account was successfully updated"
    click_on "Back"
  end

  test "should destroy Bank account" do
    visit bank_account_url(@bank_account)
    click_on "Destroy this bank account", match: :first

    assert_text "Bank account was successfully destroyed"
  end
end
