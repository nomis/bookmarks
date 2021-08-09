# SPDX-FileCopyrightText: 2021 Simon Arlott
# SPDX-License-Identifier: AGPL-3.0-or-later
# frozen_string_literal: true

class LookupURI
  MAX_LENGTH = 1.megabyte

  ALLOWED_SCHEMES = Set.new(["http", "https"]).freeze
  ALLOWED_PORTS = Set.new([80, 443, 8080]).freeze

  NORMALISER = lambda do |uri|
    uri = HTTP::URI.parse(uri)

    uri = HTTP::URI.new(
      :scheme     => uri.normalized_scheme,
      :authority  => uri.normalized_authority,
      :path       => uri.path,
      :query      => uri.query,
      :fragment   => uri.fragment,
    )

    if uri_allowed?(uri)
      uri
    else
      raise ProhibitedURIError.new(uri)
    end
  end

  class ProhibitedURIError < StandardError; end

  def self.uri_allowed?(uri)
    uri = HTTP::URI.parse(uri)

    ALLOWED_SCHEMES.include?(uri.scheme) \
      && ALLOWED_PORTS.include?(uri.port)
  end

  attr_reader :error

  def initialize(uri, user_agent = nil)
    self.error = "Missing URI" and return unless uri.present?

    @uri = uri
    @client = HTTP
      .timeout(connect: 4, read: 4)
      .nodelay
      .follow(max_hops: 3)
      .use({
          normalize_uri: {
            normalizer: NORMALISER,
          },
        },
        :auto_inflate)
      .headers("Accept-Encoding" => "gzip")
    @client = @client.headers("User-Agent" => user_agent) if user_agent.present?

    Timeout::timeout(5) do
      content = read

      page = Nokogiri::HTML(content)
      titles = page.css("title")

      if titles.length > 0
        self.title = titles[0].text
      elsif complete
        self.error = "Page has no title"
      else
        self.error = "Page has no title in the first #{content.length} #{"byte".pluralize(content.length)}"
      end
    end
  end

  def ok?
    error.nil?
  end

  def data
    { "title" => title }
  end

  protected

  attr_accessor :title
  attr_accessor :complete
  attr_writer :error

  def read
    data = +""
    self.complete = true

    @client.get(@uri).body.each do |chunk|
      data << chunk
      if data.length >= MAX_LENGTH
        self.complete = false
        break
      end
    end

    data
  ensure
    @client.close
  end
end
