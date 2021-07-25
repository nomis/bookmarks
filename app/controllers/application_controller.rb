class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :set_paper_trail_whodunnit

  def info_for_paper_trail
    { ip: request.remote_ip, user_agent: request.user_agent }
  end

  protected

  def configure_permitted_parameters
    user_attrs = [:username, :email]
    devise_parameter_sanitizer.permit :sign_up, keys: user_attrs + [:password, :password_confirmation]
    devise_parameter_sanitizer.permit :sign_in, keys: [:login, :password, :remember_me]
    devise_parameter_sanitizer.permit :account_update, keys: user_attrs + [:password, :password_confirmation, :current_password]
  end
end
