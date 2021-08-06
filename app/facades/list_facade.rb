# SPDX-FileCopyrightText: 2021 Simon Arlott
# SPDX-License-Identifier: AGPL-3.0-or-later
# frozen_string_literal: true

include Pagy::Backend

class ListFacade
  attr_reader :pagination

  def initialize(params, bookmarks, tags, search_tags = Set.new)
    @params = params
    @tags = tags.with_count.order(:key)
    # TODO: This shouldn't need to fetch the tags, because they have already been fetched above
    @pagination, @bookmarks = pagy(bookmarks.order(created_at: :desc).order(:id).includes(:tags))
    @search_tags = search_tags
  end

  def bookmarks
    @bookmark_facades ||= @bookmarks.map { |bookmark| BookmarkFacade.new(bookmark, @search_tags) }
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

  private

  attr_reader :params
end
