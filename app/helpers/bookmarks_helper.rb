# SPDX-FileCopyrightText: 2021 Simon Arlott
# SPDX-License-Identifier: AGPL-3.0-or-later
# frozen_string_literal: true

module BookmarksHelper
  def link_to_search_by_tags(tag)
    if tag.search_toggle_type == :none
      block_given? ? yield.html_safe : tag.name
    else
      link_to tag_search_href(tag), title: tag_search_title(tag), rel: "nofollow", class: tag_search_class(tag) do
        block_given? ? yield : tag.name
      end
    end
  end

  def auto_list_context(others = {})
    { search_tags: @list.search_param }.merge(others)
  end

  def auto_params_context(others = {})
    { search_tags: params[:search_tags] }.merge(others)
  end

  def auto_root_path
    context = auto_params_context
    if context[:search_tags].present?
      search_by_tags_path(tags: context[:search_tags])
    else
      root_path
    end
  end

  private

  def tag_search_href(tag)
    if tag.search_toggle_type == :all
      root_path
    else
      search_by_tags_path(tags: tag.search_toggle_tags.sort(&NaturalSort).join(","))
    end
  end

  def tag_search_title(tag)
    case tag.search_toggle_type
    when :new
      "Search by tag \"#{tag.name}\""
    when :add
      "Add tag \"#{tag.name}\" to search"
    when :remove
      "Remove tag \"#{tag.name}\" from search"
    when :all
      "All bookmarks"
    end
  end

  def tag_search_class(tag)
    tag.search_match? ? "search_remove" : "search_add"
  end
end
