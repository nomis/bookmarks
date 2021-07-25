class SessionsController < Devise::SessionsController
  before_action :validate_sign_out?, only: [:destroy]

  protected

  def validate_sign_out?
    raise ActionController::InvalidAuthenticityToken unless any_authenticity_token_valid?
  end
end
