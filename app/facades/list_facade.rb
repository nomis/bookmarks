# SPDX-FileCopyrightText: 2021 Simon Arlott
# SPDX-License-Identifier: AGPL-3.0-or-later
# frozen_string_literal: true

include ActionView::Helpers::TextHelper
include Pagy::Backend

class ListFacade
  include Rails.application.routes.url_helpers

  def initialize(params, bookmarks, tags, search_tags = Set.new, search_untagged = false, search_visibility = nil)
    @params = params
    @tags = tags.with_count.order(:key)
    # TODO: This should join the tags table when querying bookmark_tags, but it doesn't ☹️
    @bookmarks = bookmarks.order(created_at: :desc).order(:id).includes(:tags)
    @search_tags = search_tags
    @search_untagged = search_untagged
    @search_visibility = search_visibility
  end

  def bookmarks
    @bookmark_facades ||= paginated_bookmarks.map { |bookmark| BookmarkFacade.new(bookmark, @search_tags) }
  end

  def bookmarks_count
    unpaginated_bookmarks.count
  end

  def tags
    @tag_facades ||= real_tags + fake_tags
  end

  def tags_count
    real_tags.count
  end

  def name
    visibility = search_visibility? ? " #{search_visibility?.to_s}" : ""

    case type
    when :all
      if search_visibility?
        "#{search_visibility?.to_s.titlecase} bookmarks"
      else
        "All bookmarks"
      end
    when :tagged
      "Search#{visibility} bookmarks"
    when :untagged
      "Untagged#{visibility} bookmarks"
    end
  end

  def description
    case type
    when :all
      if search_visibility?
        "#{search_visibility?.to_s.titlecase} bookmarks"
      else
        nil
      end
    when :tagged
      visibility = search_visibility? ? " (#{search_visibility?.to_s} bookmarks only)" : ""

      "Search by " + pluralize(search_tags_names.size, "tag") + ": " + search_tags_names.join(", ") + visibility
    when :untagged
      visibility = search_visibility? ? " #{search_visibility?.to_s}" : ""

      "Untagged#{visibility} bookmarks"
    end
  end

  def allow_robots?
    type == :all
  end

  def search_tags_names
    @search_tags_names ||= real_tags.select(&:search_match?).map(&:name)
  end

  def search_tags_param
    return nil if @search_tags.empty?
    @search_tags_param ||= @search_tags.sort(&NaturalSort).join(",")
  end

  def search_untagged?
    @search_untagged
  end

  def search_visibility?
    @search_visibility
  end

  def untagged_count
    @bookmarks.without_tags.count
  end

  def public_count
    @bookmarks.where(private: false).count
  end

  def private_count
    @bookmarks.where(private: true).count
  end

  def empty?
    bookmarks.empty?
  end

  def pagination
    @pagination ||= Pagy.new(pagy_get_vars(@bookmarks, url: self_path))
  end

  def type
    @type ||= if search_untagged?
      :untagged
    elsif @search_tags.present?
      :tagged
    else
      :all
    end
  end

  private

  attr_reader :params

  def real_tags
    @real_tags ||= @tags.sort_by(&:key).map { |tag| TagFacade.new(tag, @search_tags) }
  end

  def fake_tags
    untags + public_tags + private_tags
  end

  # Fake tag representing public visibility
  def public_tags
    @public_tags ||= (
      search_visibility? == :public || (public_count > 0 && private_count > 0)
    ) ? [VisibilityTagFacade.new(:public, public_count, search_visibility? == :public)] : []
  end

  # Fake tag representing private visibility
  def private_tags
    @private_tags ||= (
      search_visibility? == :private || (public_count > 0 && private_count > 0)
    ) ? [VisibilityTagFacade.new(:private, private_count, search_visibility? == :private)] : []
  end

  # Fake tag representing "no tags"
  def untags
    @untags ||= (
        search_untagged? || (@tags.present? && untagged_count > 0)
      ) ? [UntaggedFacade.new(untagged_count, search_untagged?)] : []
  end

  def self_path
    case type
    when :tagged
      search_by_tags_path(tags: search_tags_param, visibility: search_visibility?&.to_s)
    when :untagged
      search_untagged_path(visibility: search_visibility?&.to_s)
    when :all
      case search_visibility?
      when :public
        search_public_path
      when :private
        search_private_path
      else
        root_path
      end
    end
  end

  def unpaginated_bookmarks
    @bookmarks
  end

  def paginated_bookmarks
    pagy_get_items(unpaginated_bookmarks, pagination)
  end
end
