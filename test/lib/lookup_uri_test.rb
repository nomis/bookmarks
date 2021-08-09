require "test_helper"
require "lib/lookup_uri_test_helper"

class LookupURITest < ActionDispatch::IntegrationTest
  include LookupURITestHelper

  test "get title" do
    responses = ResponseFetcher.new({
        "http://example.test/"  => redirect_response("https://example.test/"),
        "https://example.test/" => simple_response("<title>Test</title>"),
      })

    HTTP::Client.stub_any_instance(:perform, responses.perform_stub) do
      lookup = LookupURI.new("http://example.test")
      assert_nil(lookup.error)
      assert_equal({ "title" => "Test" }, lookup.data)
      assert(lookup.ok?)
    end
  end

  test "missing title" do
    responses = ResponseFetcher.new({
        "http://example.test/"  => redirect_response("https://example.test/"),
        "https://example.test/" => simple_response("<p>Hello World!</p>"),
      })

    HTTP::Client.stub_any_instance(:perform, responses.perform_stub) do
      lookup = LookupURI.new("http://example.test")
      assert_equal("Page has no title", lookup.error)
      assert_equal({ "title" => nil }, lookup.data)
      assert(!lookup.ok?)
    end
  end

  test "missing title (truncated)" do
    responses = ResponseFetcher.new({
        "http://example.test/"  => redirect_response("https://example.test/"),
        "https://example.test/" => chunked_response(["A" * 2.megabytes, "B" * 3.megabytes]),
      })

    HTTP::Client.stub_any_instance(:perform, responses.perform_stub) do
      lookup = LookupURI.new("http://example.test")
      assert_equal("Page has no title in the first 2097152 bytes", lookup.error)
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
    responses = ResponseFetcher.new(
        "http://example.test:81/" => simple_response("<title>Test</title>")
      )

    HTTP::Client.stub_any_instance(:perform, responses.perform_stub) do
      assert_raises LookupURI::ProhibitedURIError do
        LookupURI.new("http://example.test:81")
      end
    end
  end

  test "prohibited redirect URI" do
    responses = ResponseFetcher.new(
        "http://example.test/"  => redirect_response("http://example.test:81/"),
        "http://example.test:81/" => simple_response("<title>Test</title>")
      )

    HTTP::Client.stub_any_instance(:perform, responses.perform_stub) do
      assert_raises LookupURI::ProhibitedURIError do
        LookupURI.new("http://example.test")
      end
    end
  end

  test "prohibited deep redirect URI" do
    responses = ResponseFetcher.new(
        "http://example.test/"  => redirect_response("http://example.test/1"),
        "http://example.test/1"  => redirect_response("http://example.test/2"),
        "http://example.test/2"  => redirect_response("http://example.test:81/"),
        "http://example.test:81/" => simple_response("<title>Test</title>")
      )

    HTTP::Client.stub_any_instance(:perform, responses.perform_stub) do
      assert_raises LookupURI::ProhibitedURIError do
        LookupURI.new("http://example.test")
      end
    end
  end
end
