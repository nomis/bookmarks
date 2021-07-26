# SPDX-FileCopyrightText: 2021 Simon Arlott
# SPDX-License-Identifier: AGPL-3.0-or-later

class Bookmark < ApplicationRecord
  MAX_TAGS = 100

  has_and_belongs_to_many :tags, join_table: :bookmark_tags

  validates :title, presence: true, length: { maximum: 255 }
  validates :uri, presence: true, length: { maximum: 4096 }, format: { with: URI::regexp }
  validate :validate_tags_string

  after_save :save_tags_string
  before_destroy :remove_all_tags

  def tags_string
    (@new_tags ? @new_tags.values : tags).map(&:name).sort_by(&:downcase).join(" ")
  end

  def tags_string=(tags_string)
    @new_tags = tags_string.split.map { |name| Tag.new(name: name) }.map { |tag| [tag.key, tag] }.to_h
  end

  def self.with_tags(tags)
    tags.inject(Bookmark) do |query, tag|
      query.where(id: BookmarkTag.select(:bookmark_id).where(tag_id: tag))
    end
  end

  private

  def validate_tags_string
    return unless @new_tags

    if @new_tags.size > MAX_TAGS
      errors.add(:tags_string, "limit reached (maximum is " \
        + ActionController::Base.helpers.pluralize(MAX_TAGS, "tag") + ")")
    end

    @new_tags.values.reject(&:valid?).each do |tag|
      tag.errors.messages.values.flatten.each do |message|
        errors.add(:tags_string, "\"#{tag.name}\" #{message}")
      end
    end
  end

  def save_tags_string
    return unless @new_tags

    # Delete removed tags
    removed_tags = tags.reject { |tag| @new_tags.include?(tag.key) }.each do |tag|
      tags.delete(tag)
    end

    # Update case for the names of existing tags
    tags.reject { |tag| tag.name == @new_tags[tag.key].name }.each do |tag|
      tag.name = @new_tags[tag.key].name
      tag.save!
    end

    # Add new tags but don't update the case of the tag name
    (@new_tags.keys - tags.map(&:key)).each do |key|
      # Concurrency issue: the same tag may be created in another thread
      # (there is no way to resolve this here because we'd need a second
      # independent transaction and that could leave unreferenced tags if an
      # error occurs)
      tags << (Tag.find_by(key: key) || @new_tags[key])
    end

    # Delete tags that now have no bookmarks
    #
    # Concurrency issue: the last two users of the tag may remove it in
    # two separate threads but neither of them can identify this within
    # their own transaction, leaving the tag unreferenced
    #
    # Potential concurrency issue: the tag may be reused in another thread
    # (databases may handle conflicts with this DELETE in different ways
    # so it could silently ignore newly referenced tags or raise an error
    # on the foreign key constraint)
    Tag.where.missing(:bookmarks).where(id: removed_tags.map(&:id)).delete_all unless removed_tags.empty?

    @new_tags = nil
  end

  def remove_all_tags
    @new_tags = {}
    save_tags_string
  end
end
