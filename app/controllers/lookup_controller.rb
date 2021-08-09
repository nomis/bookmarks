# SPDX-FileCopyrightText: 2021 Simon Arlott
# SPDX-License-Identifier: AGPL-3.0-or-later
# frozen_string_literal: true

class LookupController < ApplicationController
  before_action :authenticate_user!
  before_action :delete_cookies

  # GET /url.json
  def url
    lookup = LookupURI.new(params[:uri], params[:user_agent])

    error(:bad_gateway, lookup.error) and return unless lookup.ok?

    respond_to do |format|
      format.json { render json: lookup.data }
    end
  rescue Timeout::Error, HTTP::TimeoutError => e
    error(:gateway_timeout, format_message(e))
  rescue HTTP::Error, OpenSSL::SSL::SSLError, Zlib::Error => e
    error(:service_unavailable, format_message(e))
  rescue URI::InvalidURIError,
      Addressable::URI::InvalidURIError,
      LookupURI::ProhibitedURIError => e
    error(:bad_request, format_message(e))
  end

  protected

  def error(status, message)
    render(status: status, json: { "error" => message })
  end

  def format_message(e)
    klass = e.class.to_s
    message = e.message.to_s

    if klass != message
      if klass.ends_with?("URIError")
        "#{klass.demodulize}: #{message}"
      else
        "#{klass}: #{message}"
      end
    else
      message
    end
  end
end
