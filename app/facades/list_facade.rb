# SPDX-FileCopyrightText: 2021 Simon Arlott
# SPDX-License-Identifier: AGPL-3.0-or-later
# frozen_string_literal: true

include Pagy::Backend

class ListFacade
  include Rails.application.routes.url_helpers

  def initialize(params, bookmarks, tags, search_tags = Set.new, search_untagged = false)
    @params = params
    @tags = tags.with_count.order(:key)
    # TODO: This should join the tags table when querying bookmark_tags, but it doesn't ☹️
    @bookmarks = bookmarks.order(created_at: :desc).order(:id).includes(:tags)
    @search_tags = search_tags
    @search_untagged = search_untagged
  end

  def bookmarks
    @bookmark_facades ||= paginated_bookmarks.map { |bookmark| BookmarkFacade.new(bookmark, @search_tags) }
  end

  def bookmarks_count
    unpaginated_bookmarks.count
  end

  def tags
    @tag_facades ||= @tags.sort_by(&:key).map { |tag| TagFacade.new(tag, @search_tags) } + untags
  end

  def tags_count
    tags.count - untags.count
  end

  def search_tags
    @search_tags_names ||= tags.select(&:search_match?).map(&:name)
  end

  def search_param
    return nil if @search_tags.empty?
    @search_param ||= @search_tags.sort(&NaturalSort).join(",")
  end

  def search_untagged?
    @search_untagged
  end

  def untagged_count
    @bookmarks.without_tags.count
  end

  def empty?
    bookmarks.empty?
  end

  def pagination
    @pagination ||= Pagy.new(pagy_get_vars(@bookmarks, url: self_path))
  end

  private

  attr_reader :params

  # Fake tag representing "no tags"
  def untags
    @untags ||= untagged_count > 0 ? [UntaggedFacade.new(untagged_count, search_untagged?)] : []
  end

  def self_path
    if search_param
      search_by_tags_path(tags: search_param)
    elsif search_untagged?
      search_untagged_path
    else
      root_path
    end
  end

  def unpaginated_bookmarks
    @bookmarks
  end

  def paginated_bookmarks
    pagy_get_items(unpaginated_bookmarks, pagination)
  end
end
