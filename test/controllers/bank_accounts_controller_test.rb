require "test_helper"

class BankAccountsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @bank_account = bank_accounts(:one)
  end

  test "should get index" do
    get bank_accounts_url
    assert_response :success
  end

  test "should get new" do
    get new_bank_account_url
    assert_response :success
  end

  test "should create bank_account" do
    assert_difference("BankAccount.count") do
      post bank_accounts_url, params: { bank_account: { address: @bank_account.address, cap: @bank_account.cap, default: @bank_account.default, fiscal_code: @bank_account.fiscal_code, iban: @bank_account.iban, owner: @bank_account.owner, town: @bank_account.town, user_id: @bank_account.user_id } }
    end

    assert_redirected_to bank_account_url(BankAccount.last)
  end

  test "should show bank_account" do
    get bank_account_url(@bank_account)
    assert_response :success
  end

  test "should get edit" do
    get edit_bank_account_url(@bank_account)
    assert_response :success
  end

  test "should update bank_account" do
    patch bank_account_url(@bank_account), params: { bank_account: { address: @bank_account.address, cap: @bank_account.cap, default: @bank_account.default, fiscal_code: @bank_account.fiscal_code, iban: @bank_account.iban, owner: @bank_account.owner, town: @bank_account.town, user_id: @bank_account.user_id } }
    assert_redirected_to bank_account_url(@bank_account)
  end

  test "should destroy bank_account" do
    assert_difference("BankAccount.count", -1) do
      delete bank_account_url(@bank_account)
    end

    assert_redirected_to bank_accounts_url
  end
end
