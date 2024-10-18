require "test_helper"

class VeichleCategoriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @veichle_category = veichle_categories(:one)
  end

  test "should get index" do
    get veichle_categories_url
    assert_response :success
  end

  test "should get new" do
    get new_veichle_category_url
    assert_response :success
  end

  test "should create veichle_category" do
    assert_difference("VeichleCategory.count") do
      post veichle_categories_url, params: { veichle_category: { label: @veichle_category.label } }
    end

    assert_redirected_to veichle_category_url(VeichleCategory.last)
  end

  test "should show veichle_category" do
    get veichle_category_url(@veichle_category)
    assert_response :success
  end

  test "should get edit" do
    get edit_veichle_category_url(@veichle_category)
    assert_response :success
  end

  test "should update veichle_category" do
    patch veichle_category_url(@veichle_category), params: { veichle_category: { label: @veichle_category.label } }
    assert_redirected_to veichle_category_url(@veichle_category)
  end

  test "should destroy veichle_category" do
    assert_difference("VeichleCategory.count", -1) do
      delete veichle_category_url(@veichle_category)
    end

    assert_redirected_to veichle_categories_url
  end
end
