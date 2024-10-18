require "application_system_test_case"

class ReimboursementsTest < ApplicationSystemTestCase
  setup do
    @reimboursement = reimboursements(:one)
  end

  test "visiting the index" do
    visit reimboursements_url
    assert_selector "h1", text: "Reimboursements"
  end

  test "should create reimboursement" do
    visit reimboursements_url
    click_on "New reimboursement"

    fill_in "Bank account", with: @reimboursement.bank_account_id
    fill_in "Paypal account", with: @reimboursement.paypal_account_id
    fill_in "State", with: @reimboursement.state_id
    fill_in "User", with: @reimboursement.user_id
    click_on "Create Reimboursement"

    assert_text "Reimboursement was successfully created"
    click_on "Back"
  end

  test "should update Reimboursement" do
    visit reimboursement_url(@reimboursement)
    click_on "Edit this reimboursement", match: :first

    fill_in "Bank account", with: @reimboursement.bank_account_id
    fill_in "Paypal account", with: @reimboursement.paypal_account_id
    fill_in "State", with: @reimboursement.state_id
    fill_in "User", with: @reimboursement.user_id
    click_on "Update Reimboursement"

    assert_text "Reimboursement was successfully updated"
    click_on "Back"
  end

  test "should destroy Reimboursement" do
    visit reimboursement_url(@reimboursement)
    click_on "Destroy this reimboursement", match: :first

    assert_text "Reimboursement was successfully destroyed"
  end
end
