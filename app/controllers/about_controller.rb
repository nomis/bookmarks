# SPDX-FileCopyrightText: 2021 Simon Arlott
# SPDX-License-Identifier: AGPL-3.0-or-later
# frozen_string_literal: true

class AboutController < ApplicationController
  before_action :delete_cookies

  # GET /source
  def source
    @source_code_name = Rails.configuration.x.source_code_name
    @source_code_url = Rails.configuration.x.source_code_url
  end
end
