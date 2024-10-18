require "application_system_test_case"

class FuelsTest < ApplicationSystemTestCase
  setup do
    @fuel = fuels(:one)
  end

  test "visiting the index" do
    visit fuels_url
    assert_selector "h1", text: "Fuels"
  end

  test "should create fuel" do
    visit fuels_url
    click_on "New fuel"

    fill_in "Label", with: @fuel.label
    click_on "Create Fuel"

    assert_text "Fuel was successfully created"
    click_on "Back"
  end

  test "should update Fuel" do
    visit fuel_url(@fuel)
    click_on "Edit this fuel", match: :first

    fill_in "Label", with: @fuel.label
    click_on "Update Fuel"

    assert_text "Fuel was successfully updated"
    click_on "Back"
  end

  test "should destroy Fuel" do
    visit fuel_url(@fuel)
    click_on "Destroy this fuel", match: :first

    assert_text "Fuel was successfully destroyed"
  end
end
