class ApplicationController < ActionController::Base
  allow_browser versions: :modern

  before_action :authenticate_user!, :set_locale

  # Configure additional parameters for Devise
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def set_locale
    I18n.locale = current_user&.locale&.to_sym || I18n.default_locale
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :name, :surname, :telephone, :fiscal_code, :locale ])

    if current_user&.admin?
      devise_parameter_sanitizer.permit(:account_update, keys: [ :name, :surname, :telephone, :fiscal_code, :role_id, :locale ])
    else
      devise_parameter_sanitizer.permit(:account_update, keys: [ :name, :surname, :telephone, :fiscal_code, :locale ])
    end
  end

  def ensure_admin
    unless current_user&.admin?
      redirect_back(fallback_location: root_path, alert: t("controllers.application.access_denied"))
    end
  end

  def admin_required
    redirect_to root_path, alert: t("controllers.application.access_denied_short") unless current_user&.admin?
  end

  def ensure_admin_or_redirect_to(path, message = nil)
    unless current_user&.admin?
      redirect_to path, alert: message || t("controllers.application.admin_only")
    end
  end
end
