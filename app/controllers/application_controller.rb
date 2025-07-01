class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  
  # Require user authentication for all actions
  before_action :authenticate_user!
  
  # Configure additional parameters for Devise
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :surname, :telephone, :username])
    
    if current_user&.admin?
      devise_parameter_sanitizer.permit(:account_update, keys: [:name, :surname, :telephone, :username, :role_id])
    else
      devise_parameter_sanitizer.permit(:account_update, keys: [:name, :surname, :telephone, :username])
    end
  end
end
