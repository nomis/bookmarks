# SPDX-FileCopyrightText: 2021 Simon Arlott
# SPDX-License-Identifier: AGPL-3.0-or-later
# frozen_string_literal: true

require "test_helper"

class TagCountTest < ActiveSupport::TestCase
  setup do
    @one = bookmarks(:one)
    @two = bookmarks(:two)
    @three = bookmarks(:three)
    @four = bookmarks(:four)

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
  end

  test "count tags" do
    assert_equal([
        ["common", 4],
        ["private", 2],
        ["shared1", 2],
        ["shared2", 2],
        ["test1", 1],
        ["test2", 1],
        ["test3", 1],
        ["test4", 1],
      ], Tag.with_count.order(:key).map { |tag| [tag.name, tag.count] })
  end

  test "count tags for user" do
    assert_equal([
      ["common", 4],
      ["private", 2],
      ["shared1", 2],
      ["shared2", 2],
      ["test1", 1],
      ["test2", 1],
      ["test3", 1],
      ["test4", 1],
    ], Tag.for_user(true).with_count.order(:key).map { |tag| [tag.name, tag.count] })
  end

  test "count tags for guest" do
    assert_equal([
      ["common", 2],
      ["shared1", 1],
      ["shared2", 1],
      ["test1", 1],
      ["test2", 1],
    ], Tag.for_user(false).with_count.order(:key).map { |tag| [tag.name, tag.count] })
  end

  test "count filtered tags" do
    tags1 = Set.new(Tag.where(name: "shared1").pluck(:id))

    assert_equal([
        ["common", 2],
        ["private", 1],
        ["shared1", 2],
        ["test1", 1],
        ["test3", 1],
      ], Tag.common_tags(tags1).with_count.order(:key).map { |tag| [tag.name, tag.count] })

    tags2 = Set.new(Tag.where(name: "shared2").pluck(:id))

    assert_equal([
        ["common", 2],
        ["private", 1],
        ["shared2", 2],
        ["test2", 1],
        ["test4", 1],
      ], Tag.common_tags(tags2).with_count.order(:key).map { |tag| [tag.name, tag.count] })
  end

  test "count filtered tags for user" do
    tags1 = Set.new(Tag.where(name: "shared1").pluck(:id))

    assert_equal([
        ["common", 2],
        ["private", 1],
        ["shared1", 2],
        ["test1", 1],
        ["test3", 1],
      ], Tag.for_user(true).common_tags(tags1).with_count.order(:key).map { |tag| [tag.name, tag.count] })

    tags2 = Set.new(Tag.where(name: "shared2").pluck(:id))

    assert_equal([
        ["common", 2],
        ["private", 1],
        ["shared2", 2],
        ["test2", 1],
        ["test4", 1],
      ], Tag.for_user(true).common_tags(tags2).with_count.order(:key).map { |tag| [tag.name, tag.count] })
  end

  test "count filtered tags for guest" do
    tags1 = Set.new(Tag.where(name: "shared1").pluck(:id))

    assert_equal([
        ["common", 1],
        ["shared1", 1],
        ["test1", 1],
      ], Tag.for_user(false).common_tags(tags1).with_count.order(:key).map { |tag| [tag.name, tag.count] })

    tags2 = Set.new(Tag.where(name: "shared2").pluck(:id))

    assert_equal([
        ["common", 1],
        ["shared2", 1],
        ["test2", 1],
      ], Tag.for_user(false).common_tags(tags2).with_count.order(:key).map { |tag| [tag.name, tag.count] })
  end
end
