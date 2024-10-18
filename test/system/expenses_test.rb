require "application_system_test_case"

class ExpensesTest < ApplicationSystemTestCase
  setup do
    @expense = expenses(:one)
  end

  test "visiting the index" do
    visit expenses_url
    assert_selector "h1", text: "Expenses"
  end

  test "should create expense" do
    visit expenses_url
    click_on "New expense"

    fill_in "Amount", with: @expense.amount
    fill_in "Arrival", with: @expense.arrival
    fill_in "Brand", with: @expense.brand
    fill_in "Calculation date", with: @expense.calculation_date
    check "Car" if @expense.car
    fill_in "Carburante", with: @expense.carburante
    fill_in "veichle_category", with: @expense.veichle_category_id
    fill_in "Date", with: @expense.date
    fill_in "Departure", with: @expense.departure
    fill_in "Distance", with: @expense.distance
    fill_in "Fuel", with: @expense.fuel_id
    fill_in "Manutenzione", with: @expense.manutenzione
    fill_in "Model", with: @expense.model
    fill_in "Pneumatici", with: @expense.pneumatici
    fill_in "Project", with: @expense.project_id
    fill_in "Purpose", with: @expense.purpose
    fill_in "Quota capitale", with: @expense.quota_capitale
    fill_in "Reimboursment", with: @expense.reimboursment_id
    check "Return trip" if @expense.return_trip
    click_on "Create Expense"

    assert_text "Expense was successfully created"
    click_on "Back"
  end

  test "should update Expense" do
    visit expense_url(@expense)
    click_on "Edit this expense", match: :first

    fill_in "Amount", with: @expense.amount
    fill_in "Arrival", with: @expense.arrival
    fill_in "Brand", with: @expense.brand
    fill_in "Calculation date", with: @expense.calculation_date
    check "Car" if @expense.car
    fill_in "Carburante", with: @expense.carburante
    fill_in "veichle_category", with: @expense.veichle_category_id
    fill_in "Date", with: @expense.date
    fill_in "Departure", with: @expense.departure
    fill_in "Distance", with: @expense.distance
    fill_in "Fuel", with: @expense.fuel_id
    fill_in "Manutenzione", with: @expense.manutenzione
    fill_in "Model", with: @expense.model
    fill_in "Pneumatici", with: @expense.pneumatici
    fill_in "Project", with: @expense.project_id
    fill_in "Purpose", with: @expense.purpose
    fill_in "Quota capitale", with: @expense.quota_capitale
    fill_in "Reimboursment", with: @expense.reimboursment_id
    check "Return trip" if @expense.return_trip
    click_on "Update Expense"

    assert_text "Expense was successfully updated"
    click_on "Back"
  end

  test "should destroy Expense" do
    visit expense_url(@expense)
    click_on "Destroy this expense", match: :first

    assert_text "Expense was successfully destroyed"
  end
end
