require "test_helper"

class FundTest < ActiveSupport::TestCase
  setup do
    @fund = funds(:one)
  end

  test "valid fund from fixtures" do
    assert @fund.valid?
  end

  test "has_many reimboursements" do
    assert_respond_to @fund, :reimboursements
  end

  test "has_many expenses" do
    assert_respond_to @fund, :expenses
  end

  test "total_expenses sums expenses amount" do
    assert_respond_to @fund, :total_expenses
  end
end
