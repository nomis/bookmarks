require "test_helper"

class LookupURITest < ActionDispatch::IntegrationTest
  class ResponseStream
    def initialize(body)
      @chunks = [body]
    end

    def readpartial
      @chunks.shift
    end
  end

  def make_responses(responses)
    responses = responses.each_with_object({}) do |(k, v), o|
      o[HTTP::URI.parse k] = v
    end

    lambda do |request, options|
      responses.fetch(request.uri)
    end
  end

  def redirect_response(location, status = 302)
    HTTP::Response.new(
      :status  => status,
      :version => "1.1",
      :headers => {"Location" => location},
      :body    => HTTP::Response::Body.new(ResponseStream.new(""), encoding: Encoding::UTF_8)
    )
  end

  def simple_response(body, status = 200)
    HTTP::Response.new(
      :status  => status,
      :version => "1.1",
      :body    => HTTP::Response::Body.new(ResponseStream.new(body), encoding: Encoding::UTF_8)
    )
  end

  test "get title" do
    responses = make_responses({
        "http://example.test/"  => redirect_response("https://example.test/"),
        "https://example.test/" => simple_response("<title>Test</title>"),
      })

    HTTP::Client.stub_any_instance(:perform, responses) do
      lookup = LookupURI.new("http://example.test")
      assert_nil(lookup.error)
      assert_equal({ "title" => "Test" }, lookup.data)
      assert(lookup.ok?)
    end
  end

  test "missing title" do
    responses = make_responses({
        "http://example.test/"  => redirect_response("https://example.test/"),
        "https://example.test/" => simple_response("<p>Hello World!</p>"),
      })

    HTTP::Client.stub_any_instance(:perform, responses) do
      lookup = LookupURI.new("http://example.test")
      assert_equal("Page has no title in the first 19 bytes", lookup.error)
      assert_equal({ "title" => nil }, lookup.data)
      assert(!lookup.ok?)
    end
  end

  test "missing first URI" do
    lookup = LookupURI.new(nil)
    assert_equal("Missing URI", lookup.error)
    assert_equal({ "title" => nil }, lookup.data)
    assert(!lookup.ok?)
  end

  test "invalid first URI" do
    assert_raises URI::InvalidURIError, Addressable::URI::InvalidURIError do
      LookupURI.new("http://")
    end
  end

  test "prohibited first URI" do
    responses = make_responses(
        "http://example.test:81/" => simple_response("<title>Test</title>")
      )

    HTTP::Client.stub_any_instance(:perform, responses) do
      assert_raises LookupURI::ProhibitedURIError do
        LookupURI.new("http://example.test:81")
      end
    end
  end

  test "prohibited redirect URI" do
    responses = make_responses(
        "http://example.test/"  => redirect_response("http://example.test:81/"),
        "http://example.test:81/" => simple_response("<title>Test</title>")
      )

    HTTP::Client.stub_any_instance(:perform, responses) do
      assert_raises LookupURI::ProhibitedURIError do
        LookupURI.new("http://example.test")
      end
    end
  end

  test "prohibited deep redirect URI" do
    responses = make_responses(
        "http://example.test/"  => redirect_response("http://example.test/1"),
        "http://example.test/1"  => redirect_response("http://example.test/2"),
        "http://example.test/2"  => redirect_response("http://example.test:81/"),
        "http://example.test:81/" => simple_response("<title>Test</title>")
      )

    HTTP::Client.stub_any_instance(:perform, responses) do
      assert_raises LookupURI::ProhibitedURIError do
        LookupURI.new("http://example.test")
      end
    end
  end
end
