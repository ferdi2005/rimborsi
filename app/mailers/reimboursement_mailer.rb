class ReimboursementMailer < ApplicationMailer
  default from: "noreply@rimborsi.app"

  def note_added(note)
    @note = note
    @reimboursement = note.reimboursement
    @user = @reimboursement.user
    @author = note.user

    mail(
      to: @user.email,
      subject: "Nuova nota aggiunta al Rimborso ##{@reimboursement.id}"
    )
  end

  def status_changed(reimboursement, note = nil)
    @reimboursement = reimboursement
    @user = reimboursement.user
    @note = note
    @author = note&.user

    mail(
      to: @user.email,
      subject: "Stato rimborso ##{@reimboursement.id} aggiornato a: #{@reimboursement.status_in_italian}"
    )
  end

  def admin_note_notification(note)
    @note = note
    @reimboursement = note.reimboursement
    @user = @reimboursement.user
    @author = note.user

    admin_email = ENV["EMAIL_AMMINISTRAZIONE"] || ENV["ADDRESS"]

    mail(
      to: admin_email,
      subject: "Nuova nota da utente - Rimborso ##{@reimboursement.id}"
    )
  end
end
