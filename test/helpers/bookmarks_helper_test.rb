# SPDX-FileCopyrightText: 2021 Simon Arlott
# SPDX-License-Identifier: AGPL-3.0-or-later

require "test_helper"

class BookmarksHelperTest < ActionView::TestCase
  setup do
    @one = tags(:one)
    @two = tags(:two)
    @three = tags(:three)
    @ten = tags(:ten)
  end

  test "begin searching" do
    search = Set.new()
    tag = TagFacade.new(@one, search)
    assert_equal(search_by_tags_path(tags: "#{@one.id}"), tag_search_href(nil, tag))
    assert_equal("Search by tag \"One\"", tag_search_title(nil, tag))
    assert_equal("search_add", tag_search_class(tag))
  end

  test "add tag to search" do
    search = Set.new([@one.id])
    tag = TagFacade.new(@two, search)
    assert_equal(search_by_tags_path(tags: "#{@one.id},#{@two.id}"), tag_search_href(nil, tag))
    assert_equal("Add tag \"Two\" to search", tag_search_title(nil, tag))
    assert_equal("search_add", tag_search_class(tag))

    search = Set.new([@three.id, @two.id])
    tag = TagFacade.new(@one, search)
    assert_equal(search_by_tags_path(tags: "#{@one.id},#{@two.id},#{@three.id}"), tag_search_href(nil, tag))
    assert_equal("Add tag \"One\" to search", tag_search_title(nil, tag))
    assert_equal("search_add", tag_search_class(tag))
  end

  test "remove tag from search" do
    search = Set.new([@two.id, @one.id])
    tag = TagFacade.new(@two, search)
    assert_equal(search_by_tags_path(tags: "#{@one.id}"), tag_search_href(nil, tag))
    assert_equal("Remove tag \"Two\" from search", tag_search_title(nil, tag))
    assert_equal("search_remove", tag_search_class(tag))

    search = Set.new([@three.id, @two.id, @one.id])
    tag = TagFacade.new(@one, search)
    assert_equal(search_by_tags_path(tags: "#{@two.id},#{@three.id}"), tag_search_href(nil, tag))
    assert_equal("Remove tag \"One\" from search", tag_search_title(nil, tag))
    assert_equal("search_remove", tag_search_class(tag))
  end

  test "stop searching" do
    search = Set.new([@one.id])
    tag = TagFacade.new(@one, search)
    assert_equal(root_path, tag_search_href(nil, tag))
    assert_equal("All bookmarks", tag_search_title(nil, tag))
    assert_equal("search_remove", tag_search_class(tag))
  end

  test "tag ordering" do
    search = Set.new([@ten.id, @two.id])
    tag = TagFacade.new(@three, search)
    assert_equal(search_by_tags_path(tags: "#{@two.id},#{@three.id},#{@ten.id}"), tag_search_href(nil, tag))

    search = Set.new([@three.id, @two.id])
    tag = TagFacade.new(@ten, search)
    assert_equal(search_by_tags_path(tags: "#{@two.id},#{@three.id},#{@ten.id}"), tag_search_href(nil, tag))
  end
end
