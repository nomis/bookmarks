# SPDX-FileCopyrightText: 2021 Simon Arlott
# SPDX-License-Identifier: AGPL-3.0-or-later

class Tag < ApplicationRecord
  has_and_belongs_to_many :bookmarks, join_table: :bookmark_tags

  has_paper_trail skip: [:created_at, :updated_at]

  validates :name, presence: true, length: { maximum: 255 }, format: { with: /\A[A-Za-z0-9_+&.-]+\z/ }
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

  def self.with_count(*others)
    others.inject(BookmarkTag.joins(:tag)) do |query, other|
      query.merge(other)
    end.group(:tag).count
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
