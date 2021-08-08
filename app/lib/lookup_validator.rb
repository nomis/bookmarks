# SPDX-FileCopyrightText: 2021 Simon Arlott
# SPDX-License-Identifier: AGPL-3.0-or-later
# frozen_string_literal: true

module LookupValidator
  ALLOWED_SCHEMES = Set.new(["http", "https"]).freeze
  ALLOWED_PORTS = Set.new([80, 443, 8080]).freeze

  def self.uri_allowed?(uri)
    uri = HTTP::URI.parse(uri)

    ALLOWED_SCHEMES.include?(uri.scheme) \
      && ALLOWED_PORTS.include?(uri.port)
  end

  class ProhibitedURIError < StandardError; end

  class Instrumenter < HTTP::Features::Instrumentation::NullInstrumenter
    def start(name, payload)
      if name == "start_request.http"
        uri = payload[:request].uri
        raise ProhibitedURIError.new(uri) if !LookupValidator.uri_allowed?(uri)
      end
    end
  end
end
