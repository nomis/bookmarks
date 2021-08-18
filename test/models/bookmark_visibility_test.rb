# SPDX-FileCopyrightText: 2021 Simon Arlott
# SPDX-License-Identifier: AGPL-3.0-or-later
# frozen_string_literal: true

require "test_helper"

class BookmarkVisibilityTest < ActiveSupport::TestCase
  setup do
    @one = bookmarks(:one)
    @two = bookmarks(:two)
    @three = bookmarks(:three)
    @four = bookmarks(:four)
    @five = bookmarks(:five)
    @six = bookmarks(:six)

    @one.tags_string = "common test1 shared1"
    @one.private = false
    assert @one.save

    @two.tags_string = "common test2 shared2"
    @two.private = false
    assert @two.save

    @three.tags_string = "common test3 shared1 private"
    @three.private = true
    assert @three.save

    @four.tags_string = "common test4 shared2 private"
    @four.private = true
    assert @four.save

    # @five is public

    @six.private = true
    assert @six.save
  end

  test "all bookmarks" do
    assert_equal(Set.new(["One", "Two", "Three", "Four", "Five", "Six"]), Set.new(Bookmark.all.pluck(:title)))
  end

  test "all bookmarks for user" do
    assert_equal(Set.new(["One", "Two", "Three", "Four", "Five", "Six"]), Set.new(Bookmark.for_user(true).pluck(:title)))
  end

  test "all bookmarks for guest" do
    assert_equal(Set.new(["One", "Two", "Five"]), Set.new(Bookmark.for_user(false).pluck(:title)))
  end

  test "filtered bookmarks" do
    tags1 = Set.new(Tag.where(name: "shared1").pluck(:id))
    assert_equal(Set.new(["One", "Three"]), Set.new(Bookmark.with_tags(tags1).pluck(:title)))

    tags2 = Set.new(Tag.where(name: "shared2").pluck(:id))
    assert_equal(Set.new(["Two", "Four"]), Set.new(Bookmark.with_tags(tags2).pluck(:title)))
  end

  test "filtered bookmarks for user" do
    tags1 = Set.new(Tag.where(name: "shared1").pluck(:id))
    assert_equal(Set.new(["One", "Three"]), Set.new(Bookmark.for_user(true).with_tags(tags1).pluck(:title)))

    tags2 = Set.new(Tag.where(name: "shared2").pluck(:id))
    assert_equal(Set.new(["Two", "Four"]), Set.new(Bookmark.for_user(true).with_tags(tags2).pluck(:title)))
  end

  test "filtered bookmarks for guest" do
    tags1 = Set.new(Tag.where(name: "shared1").pluck(:id))
    assert_equal(Set.new(["One"]), Set.new(Bookmark.for_user(false).with_tags(tags1).pluck(:title)))

    tags2 = Set.new(Tag.where(name: "shared2").pluck(:id))
    assert_equal(Set.new(["Two"]), Set.new(Bookmark.for_user(false).with_tags(tags2).pluck(:title)))
  end
end

