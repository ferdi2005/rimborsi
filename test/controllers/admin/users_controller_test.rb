require "test_helper"

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = users(:two)
    @user = users(:one)
    sign_in @admin
  end

  test "should get index" do
    get admin_users_url
    assert_response :success
  end

  test "should show user" do
    get admin_user_url(@user)
    assert_response :success
  end

  test "should get edit" do
    get edit_admin_user_url(@user)
    assert_response :success
  end

  test "should update user" do
    patch admin_user_url(@user), params: {
      user: {
        name: "Mario Modificato",
        surname: "Rossi",
        email: @user.email,
        telephone: "123456789",
        fiscal_code: "RSSMRA80A01H501Z"
      }
    }
    assert_redirected_to admin_user_url(@user)
  end

  test "should deactivate and activate user" do
    patch deactivate_admin_user_url(@user)
    assert_redirected_to admin_user_url(@user)
    assert_not @user.reload.active?

    patch activate_admin_user_url(@user)
    assert_redirected_to admin_user_url(@user)
    assert @user.reload.active?
  end

  test "non-admin cannot access index" do
    sign_out @admin
    sign_in @user

    get admin_users_url
    assert_redirected_to root_url
  end
end
