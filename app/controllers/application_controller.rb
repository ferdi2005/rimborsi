class ApplicationController < ActionController::Base
  allow_browser versions: :modern

  before_action :set_locale
  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def set_locale
    if params[:locale].present?
      session[:locale] = params[:locale]
    end
    I18n.locale = extract_locale || I18n.default_locale
  end

  def extract_locale
    parsed_locale = params[:locale] || session[:locale] || http_accept_language_locale
    I18n.available_locales.map(&:to_s).include?(parsed_locale.to_s) ? parsed_locale : nil
  end

  def http_accept_language_locale
    request.env['HTTP_ACCEPT_LANGUAGE']&.scan(/[a-z]{2}/)&.first
  end

  def default_url_options
    { locale: I18n.locale }
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :name, :surname, :telephone, :fiscal_code ])
    if current_user&.admin?
      devise_parameter_sanitizer.permit(:account_update, keys: [ :name, :surname, :telephone, :fiscal_code, :role_id ])
    else
      devise_parameter_sanitizer.permit(:account_update, keys: [ :name, :surname, :telephone, :fiscal_code ])
    end
  end

  def ensure_admin
    unless current_user&.admin?
      redirect_back(fallback_location: root_path, alert: t('controllers.application.access_denied'))
    end
  end

  def admin_required
    redirect_to root_path, alert: t('controllers.application.access_denied_short') unless current_user&.admin?
  end

  def ensure_admin_or_redirect_to(path, message = nil)
    unless current_user&.admin?
      redirect_to path, alert: message || t('controllers.application.admin_only')
    end
  end
end

