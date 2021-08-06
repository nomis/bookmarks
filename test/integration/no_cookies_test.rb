require "test_helper"

class NoCookiesTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @bookmark = bookmarks(:one)
    @user = users(:one)
    @user.password = SecureRandom.hex
    @user.password_confirmation = @user.password
    @user.save!
  end

  test "guest on index" do
    assert_empty(cookies.to_hash)

    get bookmarks_url
    assert_response :success
    assert_not_includes(response.headers, "Set-Cookie")
    assert_empty(cookies.to_hash)
  end

  test "ex-user on index" do
    assert_empty(cookies.to_hash)

    # Login to get a cookie and then sign out
    post user_session_url, params: {
      "user[login]": @user.username,
      "user[password]": @user.password,
      "user[remember_me]": "1"
    }
    assert_redirected_to root_url
    assert_includes(response.headers, "Set-Cookie")
    assert_not_empty(cookies.to_hash)

    session_cookies = cookies.to_hash

    get edit_bookmark_url(@bookmark)
    assert_response :success

    get destroy_user_session_path
    assert_redirected_to root_url

    # Cookie should be removed after logout
    # (a session is needed to display the logout message)
    get bookmarks_url
    assert_response :success
    assert_includes(response.headers, "Set-Cookie")
    response.headers["Set-Cookie"].split("\n").each do |line|
      assert_match(" max-age=0;", line)
    end
    assert_includes(cookies.to_hash, "_bookmarks_session")
    assert_equal("", cookies["_bookmarks_session"])
    assert_includes(cookies.to_hash, "remember_user_token")
    assert_equal("", cookies["remember_user_token"])

    # Delete known test cookies
    cookies.to_hash.keys.map { |key| cookies.delete(key) }

    # Try without cookies
    get bookmarks_url
    assert_response :success
    assert_not_includes(response.headers, "Set-Cookie")
    assert_empty(cookies.to_hash)

    # Try with previous cookies (they should be deleted)
    get bookmarks_url, headers: {
      "Cookie": session_cookies.map { |key, value| "#{key}=#{value}" }.join("; ")
    }
    assert_response :success
    assert_includes(response.headers, "Set-Cookie")
    response.headers["Set-Cookie"].split("\n").each do |line|
      assert_match(" max-age=0;", line)
    end
    assert_includes(cookies.to_hash, "_bookmarks_session")
    assert_equal("", cookies["_bookmarks_session"])
    assert_includes(cookies.to_hash, "remember_user_token")
    assert_equal("", cookies["remember_user_token"])
  end
end
