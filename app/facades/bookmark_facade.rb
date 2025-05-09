# SPDX-FileCopyrightText: 2021,2025 Simon Arlott
# SPDX-License-Identifier: AGPL-3.0-or-later
# frozen_string_literal: true

class BookmarkFacade
  def initialize(bookmark, search_tags = Set.new)
    @bookmark = bookmark
    @tags = bookmark.tags
    @search_tags = search_tags

    @tags = yield @tags if block_given?
  end

  def to_param
    @bookmark.to_param
  end

  def id
    @bookmark.id
  end

  def title
    @bookmark.title
  end

  def uri
    @bookmark.uri
  end

  def tags
    @tag_facades ||= @tags.sort_by(&:key).map { |tag| TagFacade.new(tag, @search_tags) }
  end

  def public?
    @public ||= @bookmark.public_visibility?
  end

  def private?
    @private ||= @bookmark.private_visibility?
  end

  def secret?
    @secret ||= @bookmark.secret_visibility?
  end

  def created_at
    @bookmark.created_at
  end
end
