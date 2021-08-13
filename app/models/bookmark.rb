# SPDX-FileCopyrightText: 2021 Simon Arlott
# SPDX-License-Identifier: AGPL-3.0-or-later
# frozen_string_literal: true

class Bookmark < ApplicationRecord
  BLOCKED_SCHEMES = Set.new(["file", "javascript"]).freeze

  MAX_TAGS = Rails.configuration.x.maximum_tags

  has_and_belongs_to_many :tags, join_table: :bookmark_tags

  scope :for_user, ->(user_signed_in) { user_signed_in ? all : where(private: false) }

  scope :with_tags, ->(tags) do
    tags.inject(self) do |query, tag|
      query.where(id: BookmarkTag.select(:bookmark_id).where(tag_id: tag))
    end
  end

  scope :without_tags, -> { where.not(id: BookmarkTag.select(:bookmark_id)) }

  validates :title, presence: true, length: { maximum: 255 }
  validates :uri, presence: true, length: { maximum: 4096 }, uniqueness: true
  validate :validate_uri
  validate :validate_tags_string

  after_save :save_tags_string
  before_destroy :remove_all_tags

  def uri=(uri)
    self[:uri] = uri
    return if uri.blank?

    begin
      uri = Addressable::URI.parse(uri)

      uri = Addressable::URI.new(
        :scheme     => uri.normalized_scheme,
        :authority  => uri.normalized_authority,
        :path       => uri.path,
        :query      => uri.query,
        :fragment   => uri.fragment,
      )

      self[:uri] = uri.to_s
    rescue Addressable::URI::InvalidURIError
      # Handled by validate_uri
    end
  end

  def tags_string
    (@new_tags ? @new_tags.values : tags).pluck(:name).sort_by(&:downcase).join(" ")
  end

  def tags_string=(tags_string)
    @new_tags = tags_string.split.map { |name| Tag.new(name: name) }.map { |tag| [tag.key, tag] }.to_h
  end

  private

  def validate_uri
    begin
      if uri.present? && URI::regexp !~ uri
        errors.add(:uri, "is invalid")
      elsif BLOCKED_SCHEMES.include?(Addressable::URI.parse(uri).normalized_scheme)
        errors.add(:uri, "scheme is not allowed")
      end
    rescue Addressable::URI::InvalidURIError => e
      errors.add(:uri, "is invalid")
    end
  end

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
    Tag.where.missing(:bookmarks).where(id: removed_tags.pluck(:id)).delete_all unless removed_tags.empty?

    @new_tags = nil
  end

  def remove_all_tags
    @new_tags = {}
    save_tags_string
  end
end
