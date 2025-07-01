class Users::RegistrationsController < Devise::RegistrationsController
  # Disabilita la funzionalità di cancellazione dell'account per gli utenti
  def destroy
    redirect_to edit_user_registration_path, alert: "La cancellazione dell'account non è consentita. Contatta l'amministrazione per assistenza."
  end

  protected

  def update_resource(resource, params)
    # Permetti aggiornamento senza password attuale per alcuni campi
    if params[:password].blank? && params[:password_confirmation].blank?
      resource.update_without_password(params.except(:current_password))
    else
      resource.update_with_password(params)
    end
  end

  def after_update_path_for(resource)
    edit_user_registration_path
  end
end
