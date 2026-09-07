class ReimboursementMailer < ApplicationMailer
  default from: ENV["MAIL_USERNAME"]

  def note_added(note)
    @note = note
    @reimboursement = note.reimboursement
    @user = @reimboursement.user
    @author = note.user

    I18n.with_locale(@user.locale.to_sym) do
      mail(
        to: @user.email,
        subject: t("mailers.reimboursement.note_added.subject", id: @reimboursement.id)
      )
    end
  end

  def status_changed(reimboursement, note = nil)
    @reimboursement = reimboursement
    @user = reimboursement.user
    @note = note
    @author = note&.user

    I18n.with_locale(@user.locale.to_sym) do
      mail(
        to: @user.email,
        subject: t("mailers.reimboursement.status_changed.subject_with_status", id: @reimboursement.id, status: @reimboursement.status_name, default: t("mailers.reimboursement.status_changed.subject", id: @reimboursement.id))
      )
    end
  end

  def admin_note_notification(note)
    @note = note
    @reimboursement = note.reimboursement
    @user = @reimboursement.user
    @author = note.user

    admin_email = ENV["EMAIL_AMMINISTRAZIONE"] || ENV["MAIL_USERNAME"]

    I18n.with_locale(I18n.default_locale) do
      mail(
        to: admin_email,
        subject: t("mailers.reimboursement.admin_note_notification.subject", id: @reimboursement.id, default: "Nuova nota da utente - Rimborso ##{@reimboursement.id}")
      )
    end
  end
end
