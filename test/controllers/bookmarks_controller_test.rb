require "test_helper"

class BookmarksControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    sign_in users(:one)

    @bookmark = bookmarks(:one)
  end

  test "should get index" do
    get bookmarks_url
    assert_response :success
  end

  test "should get new" do
    get new_bookmark_url
    assert_response :success
  end

  test "should create bookmark" do
    assert_difference('Bookmark.count') do
      post bookmarks_url, params: { bookmark: { title: "title", uri: "test:uri" } }
    end

    assert_redirected_to bookmark_url(Bookmark.last)
  end

  test "should show bookmark" do
    get bookmark_url(@bookmark)
    assert_response :success
  end

  test "should get edit" do
    get edit_bookmark_url(@bookmark)
    assert_response :success
  end

  test "should update bookmark" do
    patch bookmark_url(@bookmark), params: { bookmark: { title: @bookmark.title, uri: @bookmark.uri } }
    assert_redirected_to bookmark_url(@bookmark)
  end

  test "should destroy bookmark" do
    assert_difference('Bookmark.count', -1) do
      delete bookmark_url(@bookmark)
    end

    assert_redirected_to root_url
  end

  test "no tags heading when there are no tags" do
    Tag.destroy_all
    assert Bookmark.all.count > 0
    assert Tag.all.count == 0

    get bookmarks_url
    assert_response :success

    assert_select "h2", text: %r{^Bookmarks\b}
    assert_select "h2", text: %r{^Tags\b}, count: 0
  end

  test "no untagged link when there are no tags" do
    Tag.destroy_all
    assert Bookmark.all.count > 0
    assert Tag.all.count == 0

    get bookmarks_url
    assert_response :success

    assert_select "a[href=?]", search_untagged_path, count: 0
  end

  test "tags heading when there are tags" do
    b = Bookmark.first
    b.tags_string = Tag.first.name
    b.save!

    b = Bookmark.second
    b.tags_string = ""
    b.save!

    assert Bookmark.all.count > 0
    assert Tag.all.count > 0
    assert Tag.with_count.length > 0

    get bookmarks_url
    assert_response :success

    assert_select "h2", text: %r{^Bookmarks\b}
    assert_select "h2", text: %r{^Tags\b}
  end

  test "untagged link when there are tags" do
    b = Bookmark.first
    b.tags_string = Tag.first.name
    b.save!

    b = Bookmark.second
    b.tags_string = ""
    b.save!

    assert Bookmark.all.count > 0
    assert Tag.all.count > 0
    assert Tag.with_count.length > 0

    get bookmarks_url
    assert_response :success

    assert_select "a[href=?]", search_untagged_path
  end

  test "untagged link on the untagged page" do
    b = Bookmark.first
    b.tags_string = Tag.first.name
    b.save!

    b = Bookmark.second
    b.tags_string = ""
    b.save!

    assert Bookmark.all.count > 0
    assert Tag.all.count > 0
    assert Tag.with_count.length > 0

    get search_untagged_path
    assert_response :success

    assert_select "a[href=?]", root_path
  end
end
