module ApplicationHelper
  include StatusHelper

  # Helper per verificare se l'utente corrente è admin
  def admin_user?
    user_signed_in? && current_user.admin?
  end

  # Helper per verificare se l'utente corrente è admin o è il proprietario di un oggetto
  def admin_or_owner?(object)
    admin_user? || (object.respond_to?(:user) && object.user == current_user)
  end

  # Helper per mostrare contenuto solo agli admin
  def admin_only(&block)
    capture(&block) if admin_user?
  end

  # Helper per mostrare contenuto solo agli admin o proprietari
  def admin_or_owner_only(object, &block)
    capture(&block) if admin_or_owner?(object)
  end
end
