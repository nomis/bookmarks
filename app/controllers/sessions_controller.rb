# SPDX-FileCopyrightText: 2021 Simon Arlott
# SPDX-License-Identifier: AGPL-3.0-or-later
# frozen_string_literal: true

class SessionsController < Devise::SessionsController
  before_action :validate_sign_out?, only: [:destroy]

  def new
    super do |resource|
      resource.remember_me = true
    end
  end

  def destroy
    current_user.invalidate_all_sessions!
    super
  end

  protected

  def validate_sign_out?
    raise ActionController::InvalidAuthenticityToken unless any_authenticity_token_valid?
  end
end
