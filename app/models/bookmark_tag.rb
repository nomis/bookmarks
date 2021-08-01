# SPDX-FileCopyrightText: 2021 Simon Arlott
# SPDX-License-Identifier: AGPL-3.0-or-later
# frozen_string_literal: true

class BookmarkTag < ApplicationRecord
  belongs_to :bookmark
  belongs_to :tag

  def self.for_bookmarks_with_tags(tags)
    tags.inject(BookmarkTag) do |query, tag|
      query.where(bookmark_id: BookmarkTag.select(:bookmark_id).where(tag_id: tag))
    end
  end
end
