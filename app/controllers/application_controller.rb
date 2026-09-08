class ApplicationController < ActionController::Base
  allow_browser versions: :modern

  before_action :authenticate_user!, :set_locale

  # Configure additional parameters for Devise
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def set_locale
    I18n.locale = current_user_locale || browser_locale || :en
  end

  private

  def current_user_locale
    return nil unless current_user&.locale.present?

    loc = current_user.locale.to_sym
    I18n.available_locales.include?(loc) ? loc : nil
  end

  def browser_locale
    header = request&.headers&.[]("Accept-Language") || request&.env&.[]("HTTP_ACCEPT_LANGUAGE")
    return nil if header.blank?

    header.to_s.split(",").map do |part|
      lang, q = part.split(";q=")
      quality = q ? q.to_f : 1.0
      tag = lang.strip.split("-").first.downcase.to_sym
      [tag, quality]
    end.sort_by { |_, q| -q }.map(&:first).find do |loc|
      I18n.available_locales.include?(loc)
    end
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :name, :surname, :telephone, :fiscal_code, :locale ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :name, :surname, :telephone, :fiscal_code, :locale ])
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
