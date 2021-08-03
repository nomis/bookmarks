# SPDX-FileCopyrightText: 2021 Simon Arlott
# SPDX-License-Identifier: AGPL-3.0-or-later
# frozen_string_literal: true

class BookmarkTag < ApplicationRecord
  belongs_to :bookmark
  belongs_to :tag

  scope :for_user, ->(user_signed_in) do
    if user_signed_in
      all
    else
      where(bookmark_id: Bookmark.for_user(user_signed_in).select(:id))
    end
  end

  scope :with_tags, ->(tags) do
    tags.inject(self) do |query, tag|
      query.where(bookmark_id: BookmarkTag.select(:bookmark_id).where(tag_id: tag))
    end
  end

  scope :count_tags, -> { joins(:tag).merge(Tag.order(:key)).group(:tag).count }
end
