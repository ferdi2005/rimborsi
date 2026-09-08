require "test_helper"

class VehicleTest < ActiveSupport::TestCase
  test "latest_rates returns empty hash when no car expenses exist" do
    vehicle = vehicles(:one)
    assert_equal({}, vehicle.latest_rates)
  end

  test "latest_rates returns rates from the most recent car expense" do
    vehicle = vehicles(:one)
    reimboursement = reimboursements(:one)

    old_expense = Expense.create!(
      reimboursement: reimboursement,
      vehicle: vehicle,
      car: true,
      purpose: "Viaggio vecchio",
      date: Date.yesterday,
      calculation_date: Date.yesterday,
      departure: "Milano",
      arrival: "Bologna",
      distance: 200,
      quota_capitale: 0.1500,
      carburante: 0.1200,
      pneumatici: 0.0300,
      manutenzione: 0.0600,
      created_at: 2.days.ago
    )

    new_expense = Expense.create!(
      reimboursement: reimboursement,
      vehicle: vehicle,
      car: true,
      purpose: "Viaggio recente",
      date: Date.current,
      calculation_date: Date.current,
      departure: "Milano",
      arrival: "Roma",
      distance: 500,
      quota_capitale: 0.1850,
      carburante: 0.1350,
      pneumatici: 0.0420,
      manutenzione: 0.0780,
      created_at: 1.day.ago
    )

    rates = vehicle.latest_rates
    assert_equal BigDecimal("0.1850"), rates[:quota_capitale]
    assert_equal BigDecimal("0.0420"), rates[:pneumatici]
    assert_equal BigDecimal("0.0780"), rates[:manutenzione]
  end

  test "latest_rates_for returns a map of latest rates for given vehicles" do
    vehicle_one = vehicles(:one)
    vehicle_two = vehicles(:two)
    reimboursement = reimboursements(:one)

    Expense.create!(
      reimboursement: reimboursement,
      vehicle: vehicle_one,
      car: true,
      purpose: "Viaggio 1",
      date: Date.current,
      calculation_date: Date.current,
      departure: "Milano",
      arrival: "Torino",
      distance: 140,
      quota_capitale: 0.2000,
      carburante: 0.1000,
      pneumatici: 0.0500,
      manutenzione: 0.0800
    )

    rates_map = Vehicle.latest_rates_for([vehicle_one, vehicle_two])
    assert_includes rates_map.keys, vehicle_one.id
    assert_equal BigDecimal("0.2000"), rates_map[vehicle_one.id][:quota_capitale]
    assert_equal BigDecimal("0.0500"), rates_map[vehicle_one.id][:pneumatici]
    assert_equal BigDecimal("0.0800"), rates_map[vehicle_one.id][:manutenzione]
    assert_nil rates_map[vehicle_two.id]
  end
end
