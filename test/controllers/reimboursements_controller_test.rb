require "test_helper"

class ReimboursementsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @reimboursement = reimboursements(:one)
  end

  test "should get index" do
    get reimboursements_url
    assert_response :success
  end

  test "should get new" do
    get new_reimboursement_url
    assert_response :success
  end

  test "should create reimboursement" do
    assert_difference("Reimboursement.count") do
      post reimboursements_url, params: { reimboursement: { bank_account_id: @reimboursement.bank_account_id, paypal_account_id: @reimboursement.paypal_account_id, state_id: @reimboursement.state_id, user_id: @reimboursement.user_id } }
    end

    assert_redirected_to reimboursement_url(Reimboursement.last)
  end

  test "should show reimboursement" do
    get reimboursement_url(@reimboursement)
    assert_response :success
  end

  test "should get edit" do
    get edit_reimboursement_url(@reimboursement)
    assert_response :success
  end

  test "should update reimboursement" do
    patch reimboursement_url(@reimboursement), params: { reimboursement: { bank_account_id: @reimboursement.bank_account_id, paypal_account_id: @reimboursement.paypal_account_id, state_id: @reimboursement.state_id, user_id: @reimboursement.user_id } }
    assert_redirected_to reimboursement_url(@reimboursement)
  end

  test "should destroy reimboursement" do
    assert_difference("Reimboursement.count", -1) do
      delete reimboursement_url(@reimboursement)
    end

    assert_redirected_to reimboursements_url
  end
end
