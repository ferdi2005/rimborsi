class Note < ApplicationRecord
  belongs_to :reimboursement
  belongs_to :user

  # Validazioni
  validates :text, presence: true

  # Callbacks
  after_create :send_notification_email, if: :status_change?

  # Scope per ordinare le note più recenti per prime
  scope :recent, -> { order(created_at: :desc) }

  private

  def send_notification_email
    ReimboursementMailer.note_added(self).deliver_later
    # Invia notifica agli amministratori se la nota è creata da un utente normale
    if !user.admin?
      ReimboursementMailer.admin_note_notification(self).deliver_later
    end
  end
end
