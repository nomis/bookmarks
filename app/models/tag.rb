# SPDX-FileCopyrightText: 2021,2025 Simon Arlott
# SPDX-License-Identifier: AGPL-3.0-or-later
# frozen_string_literal: true

class Tag < ApplicationRecord
  has_and_belongs_to_many :bookmarks, join_table: :bookmark_tags

  scope :for_user_all, ->(user) {
    joins(:bookmarks).merge(Bookmark.for_user_all(user)).group(:id).uniq!(:group)
  }

  scope :for_user_hide_secret, ->(user, visibility) {
    joins(:bookmarks).merge(Bookmark.for_user_hide_secret(user, visibility)).group(:id).uniq!(:group)
  }

  scope :common_tags, ->(tags) {
    joins(:bookmarks).merge(Bookmark.with_tags(tags)).group(:id).uniq!(:group)
  }

  # Must obtain the whole tag record as well as the counts for them
  # otherwise an additional query is required to obtain all of the tags
  scope :with_count, -> do
    select(arel_table[Arel.star], arel_table[:id].count.as("count")).joins(:bookmarks).group(:id).uniq!(:group)
  end

  validates :name, presence: true, length: { maximum: 255 }, format: { with: /\A[A-Za-z0-9_+&.-]*\z/ }
  validate :name_consistent

  # Not validating key uniqueness here because an unsaved tag needs to be valid
  # even if it already exists so that Bookmark.validate_tags_string can validate
  # tag names

  def key
    self[:key]
  end

  def name=(name)
    self[:name] = name
    self[:key] = name&.downcase
  end

  def count
    self[:count]
  end

  def self.make_key(name)
    name.downcase
  end

  private

  def key=(key)
    self[:key] = key
  end

  def name_consistent
    return if key == name&.downcase

    errors.add(:base, "Key must be the lowercase version of name")
  end
end
