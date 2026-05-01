class LocalesController < ApplicationController
  skip_before_action :authenticate_user!, raise: false

  def set
    locale = params[:locale]
    if I18n.available_locales.map(&:to_s).include?(locale)
      session[:locale] = locale
    end
    redirect_back(fallback_location: root_path)
  end
end
