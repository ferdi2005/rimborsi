# Preview all emails at http://localhost:3000/rails/mailers/reimboursement_mailer
class ReimboursementMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/reimboursement_mailer/note_added
  def note_added
    ReimboursementMailer.note_added
  end

  # Preview this email at http://localhost:3000/rails/mailers/reimboursement_mailer/status_changed
  def status_changed
    ReimboursementMailer.status_changed
  end
end
