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

  test "should create draft reimboursement" do
    assert_difference("Reimboursement.count") do
      post reimboursements_url, params: {
        save_draft: "1",
        reimboursement: {
          project: "Progetto in bozza",
          role: "volunteer"
        }
      }
    end

    new_reimboursement = Reimboursement.last
    assert new_reimboursement.status_draft?
    assert_redirected_to reimboursement_url(new_reimboursement)
  end

  test "should save as draft when submission fails validation" do
    assert_difference("Reimboursement.count") do
      post reimboursements_url, params: {
        submit_reimbursement: "1",
        reimboursement: {
          project: "", # Vuoto: non valido per invio
          role: "volunteer",
          expenses_attributes: [
            {
              purpose: "Spesa test",
              amount: 15.0,
              requested_amount: 15.0,
              date: Date.current,
              car: false
            }
          ]
        }
      }
    end

    saved_draft = Reimboursement.last
    assert saved_draft.status_draft?
    assert_response :unprocessable_entity
    assert_select ".alert-danger", /progetto/i
  end

  test "should submit draft reimboursement" do
    draft = Reimboursement.create!(
      user: @user,
      bank_account: @reimboursement.bank_account,
      fund: @reimboursement.fund,
      project: "Progetto completo",
      role: "volunteer",
      status: :draft
    )
    draft.expenses.create!(
      purpose: "Spesa valida",
      amount: 10.0,
      requested_amount: 10.0,
      date: Date.current,
      car: false,
      attachment: fixture_file_upload(Rails.root.join("test/fixtures/files/test.pdf"), "application/pdf")
    )

    patch submit_reimboursement_url(draft)
    assert_redirected_to reimboursement_url(draft)
    draft.reload
    assert draft.status_created?
  end

  test "cannot submit draft reimboursement with problems via submit action" do
    draft = Reimboursement.create!(
      user: @user,
      bank_account: @reimboursement.bank_account,
      fund: @reimboursement.fund,
      project: "",
      role: "volunteer",
      status: :draft
    )
    draft.expenses.create!(
      purpose: "Spesa senza allegato",
      amount: 10.0,
      requested_amount: 10.0,
      date: Date.current,
      car: false
    )

    patch submit_reimboursement_url(draft)
    assert_redirected_to edit_reimboursement_url(draft)
    follow_redirect!
    assert_select ".alert-danger", /progetto/i

    draft.reload
    assert draft.status_draft?
  end

  test "cannot submit draft reimboursement with problems via update action" do
    draft = Reimboursement.create!(
      user: @user,
      bank_account: @reimboursement.bank_account,
      fund: @reimboursement.fund,
      project: "Progetto iniziale",
      role: "volunteer",
      status: :draft
    )
    draft.expenses.create!(
      purpose: "Spesa senza allegato",
      amount: 10.0,
      requested_amount: 10.0,
      date: Date.current,
      car: false
    )

    patch reimboursement_url(draft), params: {
      submit_reimbursement: "1",
      reimboursement: {
        project: "Progetto modificato"
      }
    }

    assert_response :unprocessable_entity
    assert_select ".alert-danger", /allegato/i

    draft.reload
    assert draft.status_draft?
  end

  test "should destroy draft reimboursement" do
    draft = Reimboursement.create!(
      user: @user,
      bank_account: @reimboursement.bank_account,
      project: "Bozza da cancellare",
      status: :draft
    )

    assert_difference("Reimboursement.count", -1) do
      delete reimboursement_url(draft)
    end

    assert_redirected_to reimboursements_url
  end

  test "cannot approve expenses when reimboursement is draft" do
    admin = users(:two)
    sign_in admin
    draft = Reimboursement.create!(
      user: @user,
      bank_account: @reimboursement.bank_account,
      project: "Bozza non approvabile",
      status: :draft
    )

    get approve_expenses_reimboursement_url(draft)
    assert_redirected_to reimboursement_url(draft)
    assert_equal "Non è possibile revisionare i giustificativi di un rimborso in bozza.", flash[:alert]
  end
end
