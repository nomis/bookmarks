# SPDX-FileCopyrightText: 2021 Simon Arlott
# SPDX-License-Identifier: AGPL-3.0-or-later
# frozen_string_literal: true

class RegistrationsController < Devise::RegistrationsController
  before_action :prevent_registration?, only: [:new, :create]

  protected

  def prevent_registration?
    if user_signed_in?
      redirect_to root_path
    else
      redirect_to new_user_session_path
    end
  end
end
