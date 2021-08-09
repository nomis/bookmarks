require "test_helper"
require "lib/lookup_uri_test_helper"

class LookupControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include LookupURITestHelper

  test "lookups require authentication" do
    get lookup_url_path(format: "json")
    assert_response :unauthorized
    assert_equal({ "error" => "You need to login before continuing." }, JSON.parse(response.body))
  end

  test "lookup without URI returns an error" do
    sign_in users(:one)

    get lookup_url_path(format: "json")
    assert_response :bad_gateway
    assert_equal({ "error" => "Missing URI" }, JSON.parse(response.body))
  end

  test "lookup with en empty URI returns an error" do
    sign_in users(:one)

    get lookup_url_path(format: "json", uri: "")
    assert_response :bad_gateway
    assert_equal({ "error" => "Missing URI" }, JSON.parse(response.body))
  end

  test "lookup with an invalid URI returns an error" do
    sign_in users(:one)

    get lookup_url_path(format: "json", uri: "http://")
    assert_response :bad_request
    assert_equal({ "error" => "InvalidURIError: Absolute URI missing hierarchical segment: 'http://'" }, JSON.parse(response.body))
  end

  test "lookup with an prohibited URI returns an error" do
    sign_in users(:one)

    get lookup_url_path(format: "json", uri: "http://example.com:81")
    assert_response :bad_request
    assert_equal({ "error" => "ProhibitedURIError: http://example.com:81/" }, JSON.parse(response.body))
  end

  test "lookup a page returns a title" do
    responses = ResponseFetcher.new({
        "http://example.test/"  => redirect_response("https://example.test/"),
        "https://example.test/" => simple_response("<title>Test</title>"),
      })

    HTTP::Client.stub_any_instance(:perform, responses.perform_stub) do
      sign_in users(:one)

      get lookup_url_path(format: "json", uri: "http://example.test")
      assert_response :success
      assert_equal({ "title" => "Test" }, JSON.parse(response.body))
    end
  end

  test "lookup a page without a title returns an error" do
    responses = ResponseFetcher.new({
        "http://example.test/"  => redirect_response("https://example.test/"),
        "https://example.test/" => simple_response("<p>Hello World!</p>"),
      })

    HTTP::Client.stub_any_instance(:perform, responses.perform_stub) do
      sign_in users(:one)

      get lookup_url_path(format: "json", uri: "http://example.test")
      assert_response :bad_gateway
      assert_equal({ "error" => "Page has no title" }, JSON.parse(response.body))
    end
  end

  test "lookups use default User-Agent" do
    responses = ResponseFetcher.new({
        "http://example.test/" => simple_response("<title>Test</title>"),
      })

    HTTP::Client.stub_any_instance(:perform, responses.perform_stub) do
      sign_in users(:one)

      get lookup_url_path(format: "json", uri: "http://example.test")
      assert_response :success
      assert_equal({ "title" => "Test" }, JSON.parse(response.body))
    end

    assert_equal(HTTP::Request::USER_AGENT, responses.requests[0].headers["User-Agent"])
  end

  test "lookups use client User-Agent" do
    responses = ResponseFetcher.new({
        "http://example.test/" => simple_response("<title>Test</title>"),
      })

    HTTP::Client.stub_any_instance(:perform, responses.perform_stub) do
      sign_in users(:one)

      get lookup_url_path(format: "json", uri: "http://example.test", user_agent: "Hello World!")
      assert_response :success
      assert_equal({ "title" => "Test" }, JSON.parse(response.body))
    end

    assert_equal("Hello World!", responses.requests[0].headers["User-Agent"])
  end
end
