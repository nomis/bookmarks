# SPDX-FileCopyrightText: 2021,2025 Simon Arlott
# SPDX-License-Identifier: AGPL-3.0-or-later
# frozen_string_literal: true

require "test_helper"

class BookmarkVisibilityTest < ActiveSupport::TestCase
  setup do
    @guest = nil
    @public_user = users(:public_user)
    @private_user = users(:private_user)
    @one = bookmarks(:one)
    @two = bookmarks(:two)
    @three = bookmarks(:three)
    @four = bookmarks(:four)
    @five = bookmarks(:five)
    @six = bookmarks(:six)

    @one.tags_string = "common test1 shared1"
    @one.public_visibility!
    assert @one.save

    @two.tags_string = "common test2 shared2"
    @two.public_visibility!
    assert @two.save

    @three.tags_string = "common test3 shared1 private"
    @three.private_visibility!
    assert @three.save

    @four.tags_string = "common test4 shared2 private"
    @four.private_visibility!
    assert @four.save

    # @five is public

    @six.private_visibility!
    assert @six.save
  end

  test "all bookmarks" do
    assert_equal(Set.new(["One", "Two", "Three", "Four", "Five", "Six"]), Set.new(Bookmark.all.pluck(:title)))
  end

  test "all bookmarks for private user" do
    assert_equal(Set.new(["One", "Two", "Three", "Four", "Five", "Six"]), Set.new(Bookmark.for_user_all(@private_user).pluck(:title)))
  end

  test "all bookmarks for public user" do
    assert_equal(Set.new(["One", "Two", "Five"]), Set.new(Bookmark.for_user_all(@public_user).pluck(:title)))
  end

  test "all bookmarks for guest" do
    assert_equal(Set.new(["One", "Two", "Five"]), Set.new(Bookmark.for_user_all(@guest).pluck(:title)))
  end

  test "filtered bookmarks" do
    tags1 = Set.new(Tag.where(name: "shared1").pluck(:id))
    assert_equal(Set.new(["One", "Three"]), Set.new(Bookmark.with_tags(tags1).pluck(:title)))

    tags2 = Set.new(Tag.where(name: "shared2").pluck(:id))
    assert_equal(Set.new(["Two", "Four"]), Set.new(Bookmark.with_tags(tags2).pluck(:title)))
  end

  test "filtered bookmarks for private user" do
    tags1 = Set.new(Tag.where(name: "shared1").pluck(:id))
    assert_equal(Set.new(["One", "Three"]), Set.new(Bookmark.for_user_all(@private_user).with_tags(tags1).pluck(:title)))

    tags2 = Set.new(Tag.where(name: "shared2").pluck(:id))
    assert_equal(Set.new(["Two", "Four"]), Set.new(Bookmark.for_user_all(@private_user).with_tags(tags2).pluck(:title)))
  end

  test "filtered bookmarks for public user" do
    tags1 = Set.new(Tag.where(name: "shared1").pluck(:id))
    assert_equal(Set.new(["One"]), Set.new(Bookmark.for_user_all(@public_user).with_tags(tags1).pluck(:title)))

    tags2 = Set.new(Tag.where(name: "shared2").pluck(:id))
    assert_equal(Set.new(["Two"]), Set.new(Bookmark.for_user_all(@public_user).with_tags(tags2).pluck(:title)))
  end

  test "filtered bookmarks for guest" do
    tags1 = Set.new(Tag.where(name: "shared1").pluck(:id))
    assert_equal(Set.new(["One"]), Set.new(Bookmark.for_user_all(@guest).with_tags(tags1).pluck(:title)))

    tags2 = Set.new(Tag.where(name: "shared2").pluck(:id))
    assert_equal(Set.new(["Two"]), Set.new(Bookmark.for_user_all(@guest).with_tags(tags2).pluck(:title)))
  end
end
