require "test_helper"

class VehiclesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get vehicles_index_url
    assert_response :success
  end

  test "should get show" do
    get vehicles_show_url
    assert_response :success
  end

  test "should get new" do
    get vehicles_new_url
    assert_response :success
  end

  test "should get create" do
    get vehicles_create_url
    assert_response :success
  end

  test "should get edit" do
    get vehicles_edit_url
    assert_response :success
  end

  test "should get update" do
    get vehicles_update_url
    assert_response :success
  end

  test "should get destroy" do
    get vehicles_destroy_url
    assert_response :success
  end
end
