module AdminAccess
  extend ActiveSupport::Concern

  included do
    # Helper method disponibile nelle viste
    helper_method :admin_user?
  end

  protected

  # Metodo per verificare se l'utente corrente è admin
  def admin_user?
    current_user&.admin?
  end

  # Metodo per assicurarsi che l'utente sia admin (per before_action)
  def ensure_admin
    unless admin_user?
      redirect_to root_path, alert: "Accesso negato. Solo gli amministratori possono accedere a questa sezione."
    end
  end

  # Metodo per assicurarsi che l'utente sia admin o il proprietario di una risorsa
  def ensure_admin_or_owner(resource_user_id)
    unless admin_user? || current_user.id == resource_user_id
      redirect_to root_path, alert: "Accesso negato. Non hai i permessi per accedere a questa risorsa."
    end
  end

  # Metodo per verificare se l'utente può vedere tutti i record o solo i propri
  def user_scope_for(model_class)
    if admin_user?
      model_class.all
    else
      model_class.where(user: current_user)
    end
  end

  # Metodo per verificare se l'utente può modificare una risorsa
  def can_modify?(resource)
    admin_user? || (resource.respond_to?(:user) && resource.user == current_user)
  end
end
