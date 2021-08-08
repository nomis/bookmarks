# SPDX-FileCopyrightText: 2021 Simon Arlott
# SPDX-License-Identifier: AGPL-3.0-or-later
# frozen_string_literal: true

class LookupController < ApplicationController
  MAX_LENGTH = 64 * 1024

  before_action :authenticate_user!
  before_action :delete_cookies

  # GET /url.json
  def url
    render(status: :bad_request, json: "Missing URI") and return unless params[:uri]

    data = {}

    Timeout::timeout(5) do
      client = HTTP.timeout(connect: 4, read: 4)
        .follow
        .use({
          normalize_uri: {
            normalizer: lambda(&:itself),
          },
        })

      begin
        response = +""

        client.get(params[:uri]).body.each do |chunk|
          response << chunk
          break if response.length >= MAX_LENGTH
        end

        page = Nokogiri::HTML(response)
        titles = page.css("title")

        if titles.length < 1
          render(status: :bad_gateway,
            json: "Page has no title in the first #{helpers.pluralize(response.length, "byte")}")
          return
        end

        data["title"] = titles[0].text
      ensure
        client.close
      end
    end

    respond_to do |format|
      format.json { render json: data }
    end
  rescue Timeout::Error, HTTP::TimeoutError => e
    render(status: :gateway_timeout, json: "#{e.class}: #{e.message}")
  rescue HTTP::Error => e
    render(status: :service_unavailable, json: "#{e.class}: #{e.message}")
  end
end
