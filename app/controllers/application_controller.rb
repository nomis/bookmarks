# SPDX-FileCopyrightText: 2021 Simon Arlott
# SPDX-License-Identifier: AGPL-3.0-or-later
# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Devise::Controllers::Rememberable

  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :extend_remember_me

  protected

  def configure_permitted_parameters
    user_attrs = [:username, :email]
    devise_parameter_sanitizer.permit :sign_up, keys: user_attrs + [:password, :password_confirmation]
    devise_parameter_sanitizer.permit :sign_in, keys: [:login, :password, :remember_me]
    devise_parameter_sanitizer.permit :account_update, keys: user_attrs + [:password, :password_confirmation, :current_password]
  end

  # Devise (4.8.0)'s extend_remember_period only runs at login so it never does
  # anything. https://github.com/heartcombo/devise/pull/5418
  def extend_remember_me
    if user_signed_in? && current_user.extend_remember_period && remember_me_is_active?(current_user)
      remember_me(current_user)
    end
  end

  # Delete all cookies unless signed in
  def delete_cookies
    if !user_signed_in?
      helpers.delete_cookies!
    end
  end
end
