require "test_helper"

class ReimboursementMailerTest < ActionMailer::TestCase
  test "note_added" do
    mail = ReimboursementMailer.note_added
    assert_equal "Note added", mail.subject
    assert_equal [ "to@example.org" ], mail.to
    assert_equal [ "from@example.com" ], mail.from
    assert_match "Hi", mail.body.encoded
  end

  test "status_changed" do
    mail = ReimboursementMailer.status_changed
    assert_equal "Status changed", mail.subject
    assert_equal [ "to@example.org" ], mail.to
    assert_equal [ "from@example.com" ], mail.from
    assert_match "Hi", mail.body.encoded
  end
end
