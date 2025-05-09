# SPDX-FileCopyrightText: 2021,2025 Simon Arlott
# SPDX-License-Identifier: AGPL-3.0-or-later
# frozen_string_literal: true

require "test_helper"

class BookmarksControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @bookmark = bookmarks(:one)
  end

  test "should get index" do
    get bookmarks_url
    assert_response :success
  end

  test "should authenticate new for guest" do
    get new_bookmark_url
    assert_redirected_to user_session_url
  end

  test "should get new for public user" do
    sign_in users(:public_user)

    get new_bookmark_url
    assert_response :success
  end

  test "should authenticate create for guest" do
    assert_no_difference('Bookmark.count') do
      post bookmarks_url, params: { bookmark: { title: "title", uri: "test:uri" } }
    end

    assert_redirected_to user_session_url
  end

  test "should create bookmark for public user" do
    sign_in users(:public_user)

    assert_difference('Bookmark.count') do
      post bookmarks_url, params: { bookmark: { title: "title", uri: "test:uri" } }
    end

    assert_redirected_to bookmark_url(Bookmark.last)
  end

  test "public user should create bookmark with public visibility" do
    sign_in users(:public_user)

    assert_difference('Bookmark.count') do
      post bookmarks_url, params: { bookmark: { title: "title", uri: "test:uri", visibility: "public" } }
    end

    assert_redirected_to bookmark_url(Bookmark.last)
    assert_equal(Bookmark.last.visibility, "public")
  end

  test "public user should create bookmark with private visibility overridden to public" do
    sign_in users(:public_user)

    assert_difference('Bookmark.count') do
      post bookmarks_url, params: { bookmark: { title: "title", uri: "test:uri", visibility: "private" } }
    end

    assert_redirected_to bookmark_url(Bookmark.last)
    assert_equal(Bookmark.last.visibility, "public")
  end

  test "public user should create bookmark with private visibility overridden to public (boolean)" do
    sign_in users(:public_user)

    assert_difference('Bookmark.count') do
      post bookmarks_url, params: { bookmark: { title: "title", uri: "test:uri", private: "on" } }
    end

    assert_redirected_to bookmark_url(Bookmark.last)
    assert_equal(Bookmark.last.visibility, "public")
  end

  test "private user should create bookmark with public visibility" do
    sign_in users(:private_user)

    assert_difference('Bookmark.count') do
      post bookmarks_url, params: { bookmark: { title: "title", uri: "test:uri", visibility: "public" } }
    end

    assert_redirected_to bookmark_url(Bookmark.last)
    assert_equal(Bookmark.last.visibility, "public")
  end

  test "private user should create bookmark with private visibility" do
    sign_in users(:private_user)

    assert_difference('Bookmark.count') do
      post bookmarks_url, params: { bookmark: { title: "title", uri: "test:uri", visibility: "private" } }
    end

    assert_redirected_to bookmark_url(Bookmark.last)
    assert_equal(Bookmark.last.visibility, "private")
  end

  test "private user should create bookmark with private visibility (boolean)" do
    sign_in users(:private_user)

    assert_difference('Bookmark.count') do
      post bookmarks_url, params: { bookmark: { title: "title", uri: "test:uri", private: "on" } }
    end

    assert_redirected_to bookmark_url(Bookmark.last)
    assert_equal(Bookmark.last.visibility, "private")
  end

  test "public user should create bookmark with secret visibility overridden to public" do
    sign_in users(:public_user)

    assert_difference('Bookmark.count') do
      post bookmarks_url, params: { bookmark: { title: "title", uri: "test:uri", visibility: "secret" } }
    end

    assert_redirected_to bookmark_url(Bookmark.last)
    assert_equal(Bookmark.last.visibility, "public")
  end

  test "private user should create bookmark with secret visibility overridden to private" do
    sign_in users(:private_user)

    assert_difference('Bookmark.count') do
      post bookmarks_url, params: { bookmark: { title: "title", uri: "test:uri", visibility: "secret" } }
    end

    assert_redirected_to bookmark_url(Bookmark.last)
    assert_equal(Bookmark.last.visibility, "private")
  end

  test "secret user should create bookmark with public visibility" do
    sign_in users(:secret_user)

    assert_difference('Bookmark.count') do
      post bookmarks_url, params: { bookmark: { title: "title", uri: "test:uri", visibility: "public" } }
    end

    assert_redirected_to bookmark_url(Bookmark.last)
    assert_equal(Bookmark.last.visibility, "public")
  end

  test "secret user should create bookmark with private visibility" do
    sign_in users(:secret_user)

    assert_difference('Bookmark.count') do
      post bookmarks_url, params: { bookmark: { title: "title", uri: "test:uri", visibility: "private" } }
    end

    assert_redirected_to bookmark_url(Bookmark.last)
    assert_equal(Bookmark.last.visibility, "private")
  end

  test "secret user should create bookmark with secret visibility" do
    sign_in users(:secret_user)

    assert_difference('Bookmark.count') do
      post bookmarks_url, params: { bookmark: { title: "title", uri: "test:uri", visibility: "secret" } }
    end

    assert_redirected_to bookmark_url(Bookmark.last)
    assert_equal(Bookmark.last.visibility, "secret")
  end

  test "public user should create bookmark with invalid visibility overridden to public" do
    sign_in users(:public_user)

    assert_difference('Bookmark.count') do
      post bookmarks_url, params: { bookmark: { title: "title", uri: "test:uri", visibility: "invalid" } }
    end

    assert_redirected_to bookmark_url(Bookmark.last)
    assert_equal(Bookmark.last.visibility, "public")
  end

  test "private user should create bookmark with invalid visibility overridden to private" do
    sign_in users(:private_user)

    assert_difference('Bookmark.count') do
      post bookmarks_url, params: { bookmark: { title: "title", uri: "test:uri", visibility: "invalid" } }
    end

    assert_redirected_to bookmark_url(Bookmark.last)
    assert_equal(Bookmark.last.visibility, "private")
  end

  test "secret user should create bookmark with invalid visibility overridden to secret" do
    sign_in users(:secret_user)

    assert_difference('Bookmark.count') do
      post bookmarks_url, params: { bookmark: { title: "title", uri: "test:uri", visibility: "invalid" } }
    end

    assert_redirected_to bookmark_url(Bookmark.last)
    assert_equal(Bookmark.last.visibility, "secret")
  end

  test "public user should observe duplicate public bookmark" do
    @bookmark.uri = "test:public_uri"
    @bookmark.public_visibility!

    sign_in users(:public_user)

    get compose_bookmark_with_session_url(title: "title", uri: "test:public_uri")
    assert_redirected_to edit_bookmark_url(@bookmark)
  end

  test "private user should observe duplicate public bookmark" do
    @bookmark.uri = "test:public_uri"
    @bookmark.public_visibility!

    sign_in users(:private_user)

    get compose_bookmark_with_session_url(title: "title", uri: "test:public_uri")
    assert_redirected_to edit_bookmark_url(@bookmark)
  end

  test "secret user should observe duplicate public bookmark" do
    @bookmark.uri = "test:public_uri"
    @bookmark.public_visibility!

    sign_in users(:secret_user)

    get compose_bookmark_with_session_url(title: "title", uri: "test:public_uri")
    assert_redirected_to edit_bookmark_url(@bookmark)
  end

  test "public user should not observe duplicate private bookmark" do
    @bookmark.uri = "test:private_uri"
    @bookmark.private_visibility!

    sign_in users(:public_user)

    get compose_bookmark_with_session_url(title: "title", uri: "test:private_uri")
    assert_redirected_to new_bookmark_url(title: "title", uri: "test:private_uri")
  end

  test "private user should observe duplicate private bookmark" do
    @bookmark.uri = "test:private_uri"
    @bookmark.private_visibility!

    sign_in users(:private_user)

    get compose_bookmark_with_session_url(title: "title", uri: "test:private_uri")
    assert_redirected_to edit_bookmark_url(@bookmark)
  end

  test "secret user should observe duplicate private bookmark" do
    @bookmark.uri = "test:private_uri"
    @bookmark.private_visibility!

    sign_in users(:secret_user)

    get compose_bookmark_with_session_url(title: "title", uri: "test:private_uri")
    assert_redirected_to edit_bookmark_url(@bookmark)
  end

  test "public user should not observe duplicate secret bookmark" do
    @bookmark.uri = "test:secret_uri"
    @bookmark.secret_visibility!

    sign_in users(:public_user)

    get compose_bookmark_with_session_url(title: "title", uri: "test:secret_uri")
    assert_redirected_to new_bookmark_url(title: "title", uri: "test:secret_uri")
  end

  test "private user should not observe duplicate secret bookmark" do
    @bookmark.uri = "test:secret_uri"
    @bookmark.secret_visibility!

    sign_in users(:private_user)

    get compose_bookmark_with_session_url(title: "title", uri: "test:secret_uri")
    assert_redirected_to new_bookmark_url(title: "title", uri: "test:secret_uri")
  end

  test "secret user should observe duplicate secret bookmark" do
    @bookmark.uri = "test:secret_uri"
    @bookmark.secret_visibility!

    sign_in users(:secret_user)

    get compose_bookmark_with_session_url(title: "title", uri: "test:secret_uri")
    assert_redirected_to edit_bookmark_url(@bookmark)
  end

  test "should show bookmark" do
    get bookmark_url(@bookmark)
    assert_response :success
  end

  test "should authenticate show private bookmark for guest" do
    @bookmark.private_visibility!

    get bookmark_url(@bookmark)
    assert_redirected_to user_session_url
  end

  test "should not show private bookmark to public user" do
    @bookmark.private_visibility!
    sign_in users(:public_user)

    assert_raises(ActiveRecord::RecordNotFound) do
      get bookmark_url(@bookmark)
    end
  end

  test "should show private bookmark to private user" do
    @bookmark.private_visibility!
    sign_in users(:private_user)

    get bookmark_url(@bookmark)
    assert_response :success
  end

  test "should show private bookmark to secret user" do
    @bookmark.private_visibility!
    sign_in users(:secret_user)

    get bookmark_url(@bookmark)
    assert_response :success
  end

  test "should authenticate show secret bookmark for guest" do
    @bookmark.secret_visibility!

    get bookmark_url(@bookmark)
    assert_redirected_to user_session_url
  end

  test "should not show secret bookmark to public user" do
    @bookmark.secret_visibility!
    sign_in users(:public_user)

    assert_raises(ActiveRecord::RecordNotFound) do
      get bookmark_url(@bookmark)
    end
  end

  test "should not show secret bookmark to private user" do
    @bookmark.secret_visibility!
    sign_in users(:private_user)

    assert_raises(ActiveRecord::RecordNotFound) do
      get bookmark_url(@bookmark)
    end
  end

  test "should show secret bookmark to secret user" do
    @bookmark.secret_visibility!
    sign_in users(:secret_user)

    get bookmark_url(@bookmark)
    assert_response :success
  end

  test "should authenticate edit for guest" do
    get edit_bookmark_url(@bookmark)
    assert_redirected_to user_session_url
  end

  test "should get edit for public user" do
    sign_in users(:public_user)

    get edit_bookmark_url(@bookmark)
    assert_response :success
  end

  test "should get edit for private user" do
    sign_in users(:private_user)

    get edit_bookmark_url(@bookmark)
    assert_response :success
  end

  test "should get edit for secret user" do
    sign_in users(:secret_user)

    get edit_bookmark_url(@bookmark)
    assert_response :success
  end

  test "should authenticate update for guest" do
    patch bookmark_url(@bookmark), params: { bookmark: { title: @bookmark.title, uri: @bookmark.uri } }
    assert_redirected_to user_session_url
  end

  test "should update bookmark for public user" do
    sign_in users(:public_user)

    patch bookmark_url(@bookmark), params: { bookmark: { title: @bookmark.title, uri: @bookmark.uri } }
    assert_redirected_to bookmark_url(@bookmark)
  end

  test "should update bookmark for private user" do
    sign_in users(:private_user)

    patch bookmark_url(@bookmark), params: { bookmark: { title: @bookmark.title, uri: @bookmark.uri } }
    assert_redirected_to bookmark_url(@bookmark)
  end

  test "should update bookmark for secret user" do
    sign_in users(:secret_user)

    patch bookmark_url(@bookmark), params: { bookmark: { title: @bookmark.title, uri: @bookmark.uri } }
    assert_redirected_to bookmark_url(@bookmark)
  end

  test "should update private bookmark for private user" do
    @bookmark.private_visibility!
    sign_in users(:private_user)

    patch bookmark_url(@bookmark), params: { bookmark: { title: @bookmark.title, uri: @bookmark.uri } }
    assert_redirected_to bookmark_url(@bookmark)
  end

  test "should update private bookmark for secret user" do
    @bookmark.private_visibility!
    sign_in users(:secret_user)

    patch bookmark_url(@bookmark), params: { bookmark: { title: @bookmark.title, uri: @bookmark.uri } }
    assert_redirected_to bookmark_url(@bookmark)
  end

  test "should update secret bookmark for secret user" do
    @bookmark.secret_visibility!
    sign_in users(:secret_user)

    patch bookmark_url(@bookmark), params: { bookmark: { title: @bookmark.title, uri: @bookmark.uri } }
    assert_redirected_to bookmark_url(@bookmark)
  end

  test "should not update private bookmark for public user" do
    @bookmark.private_visibility!
    sign_in users(:public_user)

    assert_raises(ActiveRecord::RecordNotFound) do
      patch bookmark_url(@bookmark), params: { bookmark: { title: @bookmark.title, uri: @bookmark.uri } }
    end
  end

  test "should not update secret bookmark for public user" do
    @bookmark.secret_visibility!
    sign_in users(:public_user)

    assert_raises(ActiveRecord::RecordNotFound) do
      patch bookmark_url(@bookmark), params: { bookmark: { title: @bookmark.title, uri: @bookmark.uri } }
    end
  end

  test "should not update secret bookmark for private user" do
    @bookmark.secret_visibility!
    sign_in users(:private_user)

    assert_raises(ActiveRecord::RecordNotFound) do
      patch bookmark_url(@bookmark), params: { bookmark: { title: @bookmark.title, uri: @bookmark.uri } }
    end
  end

  test "public user should update bookmark with public visibility" do
    sign_in users(:public_user)

    patch bookmark_url(@bookmark), params: { bookmark: { title: @bookmark.title, uri: @bookmark.uri, visibility: "public" } }
    assert_redirected_to bookmark_url(@bookmark)
    assert_equal(@bookmark.reload.visibility, "public")
  end

  test "public user should update bookmark with private visibility overridden to public" do
    sign_in users(:public_user)

    patch bookmark_url(@bookmark), params: { bookmark: { title: @bookmark.title, uri: @bookmark.uri, visibility: "private" } }
    assert_redirected_to bookmark_url(@bookmark)
    assert_equal(@bookmark.reload.visibility, "public")
  end

  test "public user should update bookmark with secret visibility overridden to public" do
    sign_in users(:public_user)

    patch bookmark_url(@bookmark), params: { bookmark: { title: @bookmark.title, uri: @bookmark.uri, visibility: "secret" } }
    assert_redirected_to bookmark_url(@bookmark)
    assert_equal(@bookmark.reload.visibility, "public")
  end

  test "public user should update bookmark with invalid visibility overridden to public" do
    sign_in users(:public_user)

    patch bookmark_url(@bookmark), params: { bookmark: { title: @bookmark.title, uri: @bookmark.uri, visibility: "invalid" } }
    assert_redirected_to bookmark_url(@bookmark)
    assert_equal(@bookmark.reload.visibility, "public")
  end

  test "private user should update bookmark with public visibility" do
    sign_in users(:private_user)

    patch bookmark_url(@bookmark), params: { bookmark: { title: @bookmark.title, uri: @bookmark.uri, visibility: "public" } }
    assert_redirected_to bookmark_url(@bookmark)
    assert_equal(@bookmark.reload.visibility, "public")
  end

  test "private user should update bookmark with private visibility" do
    sign_in users(:private_user)

    patch bookmark_url(@bookmark), params: { bookmark: { title: @bookmark.title, uri: @bookmark.uri, visibility: "private" } }
    assert_redirected_to bookmark_url(@bookmark)
    assert_equal(@bookmark.reload.visibility, "private")
  end

  test "private user should update bookmark with secret visibility overridden to public" do
    sign_in users(:private_user)

    patch bookmark_url(@bookmark), params: { bookmark: { title: @bookmark.title, uri: @bookmark.uri, visibility: "secret" } }
    assert_redirected_to bookmark_url(@bookmark)
    assert_equal(@bookmark.reload.visibility, "private")
  end

  test "private user should update bookmark with invalid visibility overridden to public" do
    sign_in users(:private_user)

    patch bookmark_url(@bookmark), params: { bookmark: { title: @bookmark.title, uri: @bookmark.uri, visibility: "invalid" } }
    assert_redirected_to bookmark_url(@bookmark)
    assert_equal(@bookmark.reload.visibility, "private")
  end

  test "secret user should update bookmark with public visibility" do
    sign_in users(:secret_user)

    patch bookmark_url(@bookmark), params: { bookmark: { title: @bookmark.title, uri: @bookmark.uri, visibility: "public" } }
    assert_redirected_to bookmark_url(@bookmark)
    assert_equal(@bookmark.reload.visibility, "public")
  end

  test "secret user should update bookmark with private visibility" do
    sign_in users(:secret_user)

    patch bookmark_url(@bookmark), params: { bookmark: { title: @bookmark.title, uri: @bookmark.uri, visibility: "private" } }
    assert_redirected_to bookmark_url(@bookmark)
    assert_equal(@bookmark.reload.visibility, "private")
  end

  test "secret user should update bookmark with secret visibility" do
    sign_in users(:secret_user)

    patch bookmark_url(@bookmark), params: { bookmark: { title: @bookmark.title, uri: @bookmark.uri, visibility: "secret" } }
    assert_redirected_to bookmark_url(@bookmark)
    assert_equal(@bookmark.reload.visibility, "secret")
  end

  test "secret user should update bookmark with invalid visibility overridden to public" do
    sign_in users(:secret_user)

    patch bookmark_url(@bookmark), params: { bookmark: { title: @bookmark.title, uri: @bookmark.uri, visibility: "invalid" } }
    assert_redirected_to bookmark_url(@bookmark)
    assert_equal(@bookmark.reload.visibility, "secret")
  end

  test "should authenticate destroy for guest" do
    assert_no_difference('Bookmark.count') do
      delete bookmark_url(@bookmark)
    end

    assert_redirected_to user_session_url
  end

  test "should destroy bookmark for public user" do
    sign_in users(:public_user)

    assert_difference('Bookmark.count', -1) do
      delete bookmark_url(@bookmark)
    end

    assert_redirected_to root_url
  end

  test "should destroy bookmark for private user" do
    sign_in users(:private_user)

    assert_difference('Bookmark.count', -1) do
      delete bookmark_url(@bookmark)
    end

    assert_redirected_to root_url
  end

  test "should destroy bookmark for secret user" do
    sign_in users(:secret_user)

    assert_difference('Bookmark.count', -1) do
      delete bookmark_url(@bookmark)
    end

    assert_redirected_to root_url
  end

  test "should destroy private bookmark for private user" do
    @bookmark.private_visibility!
    sign_in users(:private_user)

    assert_difference('Bookmark.count', -1) do
      delete bookmark_url(@bookmark)
    end

    assert_redirected_to root_url
  end

  test "should destroy secret bookmark for secret user" do
    @bookmark.secret_visibility!
    sign_in users(:secret_user)

    assert_difference('Bookmark.count', -1) do
      delete bookmark_url(@bookmark)
    end

    assert_redirected_to root_url
  end

  test "should not destroy private bookmark for public user" do
    @bookmark.private_visibility!
    sign_in users(:public_user)

    assert_no_difference('Bookmark.count') do
      assert_raises(ActiveRecord::RecordNotFound) do
        delete bookmark_url(@bookmark)
      end
    end
  end

  test "should not destroy secret bookmark for public user" do
    @bookmark.secret_visibility!
    sign_in users(:public_user)

    assert_no_difference('Bookmark.count') do
      assert_raises(ActiveRecord::RecordNotFound) do
        delete bookmark_url(@bookmark)
      end
    end
  end

  test "should not destroy secret bookmark for private user" do
    @bookmark.secret_visibility!
    sign_in users(:private_user)

    assert_no_difference('Bookmark.count') do
      assert_raises(ActiveRecord::RecordNotFound) do
        delete bookmark_url(@bookmark)
      end
    end
  end
end
