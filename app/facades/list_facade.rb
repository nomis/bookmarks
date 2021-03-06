# SPDX-FileCopyrightText: 2021 Simon Arlott
# SPDX-License-Identifier: AGPL-3.0-or-later

class ListFacade
  def initialize(bookmarks = Bookmark.all, tags = Tag.all, search_tags = Set.new)
    @tags = Tag.with_count(tags, Tag.order(:key))
    # TODO: This shouldn't need to fetch the tags, because they have already been fetched above
    @bookmarks = bookmarks.order(created_at: :desc).order(:id).includes(:tags)
    @search_tags = search_tags
  end

  def bookmarks
    @bookmark_facades ||= @bookmarks.map { |bookmark| BookmarkFacade.new(bookmark, @search_tags) }
  end

  def tags
    @tag_facades ||= @tags.map { |tag, count| TagFacade.new(tag, @search_tags, count) }
  end

  def search_tags
    @search_tags_names ||= tags.select(&:search_match?).map(&:name).sort(&NaturalSort)
  end
end
