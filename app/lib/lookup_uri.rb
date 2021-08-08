# SPDX-FileCopyrightText: 2021 Simon Arlott
# SPDX-License-Identifier: AGPL-3.0-or-later
# frozen_string_literal: true

class LookupURI
  MAX_LENGTH = 1.megabyte

  NORMALISER = lambda do |uri|
    uri = HTTP::URI.parse(uri)

    HTTP::URI.new(
      :scheme     => uri.normalized_scheme,
      :authority  => uri.normalized_authority,
      :path       => uri.path,
      :query      => uri.query,
      :fragment   => uri.fragment,
    )
  end

  attr_reader :error

  def initialize(uri, user_agent = nil)
    error = "Missing URI" and return unless uri.present?
    raise LookupValidator::ProhibitedURIError.new(uri) unless LookupValidator.uri_allowed?(uri)

    @uri = uri
    @client = HTTP.timeout(connect: 4, read: 4)
      .nodelay
      .follow(max_hops: 3)
      .use({
          instrumentation: {
            instrumenter: LookupValidator::Instrumenter.new,
          },
          normalize_uri: {
            normalizer: NORMALISER,
          },
        },
        :auto_inflate)
      .headers("Accept-Encoding" => "gzip")
    @client = @client.headers("User-Agent" => user_agent) if user_agent.present?

    Timeout::timeout(5) do
      content = get_partial_response

      page = Nokogiri::HTML(content)
      titles = page.css("title")

      if titles.length > 0
        self.title = titles[0].text
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
  attr_writer :error

  def get_partial_response
    data = +""

    @client.get(@uri).body.each do |chunk|
      data << chunk
      break if data.length >= MAX_LENGTH
    end

    data
  ensure
    @client.close
  end
end
