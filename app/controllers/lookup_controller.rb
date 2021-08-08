# SPDX-FileCopyrightText: 2021 Simon Arlott
# SPDX-License-Identifier: AGPL-3.0-or-later
# frozen_string_literal: true

class LookupController < ApplicationController
  MAX_LENGTH = 256 * 1024

  before_action :authenticate_user!
  before_action :delete_cookies

  # GET /url.json
  def url
    uri = params[:uri]

    render(status: :bad_request, json: "Missing URI") and return unless uri.present?
    render(status: :bad_request, json: "Prohibited URI") and return unless LookupValidator.uri_allowed?(uri)

    data = {}

    Timeout::timeout(5) do
      client = HTTP.timeout(connect: 4, read: 4)
        .follow(max_hops: 3)
        .use({
          instrumentation: {
            instrumenter: LookupValidator::Instrumenter.new,
          },
          normalize_uri: {
            normalizer: LookupNormaliser::NORMALISER,
          },
        })
      client = client.headers("User-Agent" => user_agent) if user_agent.present?
      content = get_partial_response(client, uri)

      page = Nokogiri::HTML(content)
      titles = page.css("title")

      if titles.length < 1
        render(status: :bad_gateway,
          json: "Page has no title in the first #{helpers.pluralize(content.length, "byte")}")
        return
      end

      data["title"] = titles[0].text
    end

    respond_to do |format|
      format.json { render json: data }
    end
  rescue Timeout::Error, HTTP::TimeoutError => e
    render(status: :gateway_timeout, json: "#{e.class}: #{e.message}")
  rescue HTTP::Error, OpenSSL::SSL::SSLError => e
    render(status: :service_unavailable, json: "#{e.class}: #{e.message}")
  rescue URI::InvalidURIError,
      Addressable::URI::InvalidURIError,
      LookupValidator::ProhibitedURIError => e
    render(status: :bad_request, json: "#{e.class.name.demodulize}: #{e.message}")
  end

  protected

  def get_partial_response(client, uri)
    data = +""

    client.get(uri).body.each do |chunk|
      data << chunk
      break if data.length >= MAX_LENGTH
    end

    data
  ensure
    client.close
  end
end
