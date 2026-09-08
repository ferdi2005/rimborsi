require "test_helper"

class PaymentTest < ActiveSupport::TestCase
  setup do
    @payment = Payment.create!(payment_date: Date.current, status: :paid)
    @reimboursement = reimboursements(:one)
    @reimboursement.update_column(:payment_id, @payment.id)
    @payment.recalculate_total!
  end

  test "generate_xml_flow include la causale_bonifico nel tag Ustrd" do
    xml = @payment.generate_xml_flow
    expected_causale = @reimboursement.causale_bonifico

    assert_includes xml, "<Ustrd>#{expected_causale}</Ustrd>"
    assert_includes xml, @reimboursement.fund.name
    assert_includes xml, @reimboursement.project
  end
end
