require "test_helper"

class ReimboursementsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    sign_in @user
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
      post reimboursements_url, params: {
        reimboursement: {
          bank_account_id: @reimboursement.bank_account_id,
          fund_id: @reimboursement.fund_id,
          project: "Nuovo progetto",
          role: "volunteer",
          expenses_attributes: [
            {
              purpose: "Spesa test",
              date: Date.current,
              amount: 20.0,
              requested_amount: 20.0,
              car: false,
              attachment: fixture_file_upload(Rails.root.join("test/fixtures/files/test.pdf"), "application/pdf")
            }
          ]
        }
      }
    end

    assert_redirected_to reimboursement_url(Reimboursement.last)
    assert_equal @reimboursement.fund_id, Reimboursement.last.fund_id
    assert_equal "Nuovo progetto", Reimboursement.last.project
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
    patch reimboursement_url(@reimboursement), params: {
      reimboursement: {
        project: "Progetto modificato",
        fund_id: funds(:two).id
      }
    }
    assert_redirected_to reimboursement_url(@reimboursement)
    @reimboursement.reload
    assert_equal "Progetto modificato", @reimboursement.project
    assert_equal funds(:two).id, @reimboursement.fund_id
  end

  test "should destroy reimboursement" do
    assert_difference("Reimboursement.count", -1) do
      delete reimboursement_url(@reimboursement)
    end

    assert_redirected_to reimboursements_url
  end
end
