# SPDX-FileCopyrightText: 2021 Simon Arlott
# SPDX-License-Identifier: AGPL-3.0-or-later
# frozen_string_literal: true

class TagFacade
  MAX_TAGS = Rails.configuration.x.maximum_tags

  attr_reader :count

  def initialize(tag, search_tags = Set.new, count = nil)
    @tag = tag
    @search_tags = search_tags
    @count = count
  end

  def name
    @tag.name
  end

  def search_match?
    @search_tags.include?(@tag.id)
  end

  # Include/exclude this tag from search
  def search_toggle_tags
    @search_toggle_tags ||=
      if search_match?
        @search_tags ^ [@tag.id]
      else
        @search_tags | [@tag.id]
      end
  end

  # Result of including/excluding this tag from the search
  def search_toggle_type
    if search_toggle_tags.empty?
      :all
    elsif search_match?
      :remove
    elsif search_toggle_tags.size > MAX_TAGS
      :none
    elsif search_toggle_tags.size > 1
      :add
    else
      :new
    end
  end
end
