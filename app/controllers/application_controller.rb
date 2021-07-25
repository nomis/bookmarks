class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def configure_permitted_parameters
    user_attrs = [:username, :email]
    devise_parameter_sanitizer.permit :sign_up, keys: user_attrs + [:password, :password_confirmation]
    devise_parameter_sanitizer.permit :sign_in, keys: [:login, :password, :remember_me]
    devise_parameter_sanitizer.permit :account_update, keys: user_attrs + [:password, :password_confirmation, :current_password]
  end
end
