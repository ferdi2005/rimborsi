require "application_system_test_case"

class VeichleCategoriesTest < ApplicationSystemTestCase
  setup do
    @veichle_category = veichle_categories(:one)
  end

  test "visiting the index" do
    visit veichle_categories_url
    assert_selector "h1", text: "Veichle categories"
  end

  test "should create veichle category" do
    visit veichle_categories_url
    click_on "New veichle category"

    fill_in "Label", with: @veichle_category.label
    click_on "Create Veichle category"

    assert_text "Veichle category was successfully created"
    click_on "Back"
  end

  test "should update Veichle category" do
    visit veichle_category_url(@veichle_category)
    click_on "Edit this veichle category", match: :first

    fill_in "Label", with: @veichle_category.label
    click_on "Update Veichle category"

    assert_text "Veichle category was successfully updated"
    click_on "Back"
  end

  test "should destroy Veichle category" do
    visit veichle_category_url(@veichle_category)
    click_on "Destroy this veichle category", match: :first

    assert_text "Veichle category was successfully destroyed"
  end
end
