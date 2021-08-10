# SPDX-FileCopyrightText: 2021 Simon Arlott
# SPDX-License-Identifier: AGPL-3.0-or-later
# frozen_string_literal: true

include Pagy::Backend

class ListFacade
  def initialize(params, bookmarks, tags, search_tags = Set.new)
    @params = params
    @tags = tags.with_count.order(:key)
    # TODO: This should join the tags table when querying bookmark_tags, but it doesn't ☹️
    @bookmarks = bookmarks.order(created_at: :desc).order(:id).includes(:tags)
    @search_tags = search_tags
  end

  def bookmarks
    @bookmark_facades ||= paginated_bookmarks.map { |bookmark| BookmarkFacade.new(bookmark, @search_tags) }
  end

  def tags
    @tag_facades ||= @tags.map { |tag| TagFacade.new(tag, @search_tags) }
  end

  def search_tags
    @search_tags_names ||= tags.select(&:search_match?).map(&:name).sort(&NaturalSort)
  end

  def search_param
    @search_param ||= @search_tags.sort(&NaturalSort).join(",")
  end

  def empty?
    bookmarks.empty?
  end

  def pagination
    @pagination ||= Pagy.new(pagy_get_vars(@bookmarks, {}))
  end

  private

  attr_reader :params

  def paginated_bookmarks
    pagy_get_items(@bookmarks, pagination)
  end
end
