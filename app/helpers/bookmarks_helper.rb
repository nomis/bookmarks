# SPDX-FileCopyrightText: 2021 Simon Arlott
# SPDX-License-Identifier: AGPL-3.0-or-later
# frozen_string_literal: true

module BookmarksHelper
  def link_to_search_by_tags(list, tag)
    if tag.search_toggle_type == :none
      block_given? ? yield.html_safe : tag.name
    else
      link_to tag_search_href(list, tag), title: tag_search_title(list, tag), rel: "nofollow", class: tag_search_class(tag) do
        block_given? ? yield : tag.name
      end
    end
  end

  def auto_list_context(others = {})
    {
      search_tags: @list.search_tags_param,
      search_untagged: @list.search_untagged? ? 1 : nil,
      search_visibility: @list.search_visibility?&.to_s,
    }.merge(others)
  end

  def auto_params_context(others = {})
    {
      search_tags: params[:search_tags],
      search_untagged: params[:search_untagged].to_i == 1 ? 1 : nil,
      search_visibility: ["public", "private"].include?(params[:search_visibility]) ? params[:search_visibility] : nil,
    }.merge(others)
  end

  def auto_root_path
    context = auto_params_context
    if context[:search_tags].present?
      search_by_tags_path(tags: context[:search_tags], visibility: context[:search_visibility])
    elsif context[:search_untagged]
      search_untagged_path(visibility: context[:search_visibility])
    elsif context[:search_visibility] == "public"
      search_public_path
    elsif context[:search_visibility] == "private"
      search_private_path
    else
      root_path
    end
  end

  private

  def tag_search_href(list, tag)
    case tag.search_toggle_type
    when :all
      case list&.search_visibility?
      when :public
        search_public_path
      when :private
        search_private_path
      else
        root_path
      end
    when :untagged
      search_untagged_path(visibility: list&.search_visibility?&.to_s)
    when :public, :private, :any_visibility
      visibility = tag.search_toggle_type == :any_visibility ? nil : tag.search_toggle_type.to_s

      case list&.type
      when :tagged
        search_by_tags_path(tags: list&.search_tags_param, visibility: visibility)
      when :untagged
        search_untagged_path(visibility: visibility)
      else
        case tag.search_toggle_type
        when :public
          search_public_path
        when :private
          search_private_path
        when :any_visibility
          root_path
        end
      end
    else # :new, :add, :remove
      search_by_tags_path(tags: tag.search_toggle_tags.sort(&NaturalSort).join(","),
        visibility: list&.search_visibility?&.to_s)
    end
  end

  def tag_search_title(list, tag)
    case tag.search_toggle_type
    when :new
      "Search by tag \"#{tag.name}\""
    when :add
      "Add tag \"#{tag.name}\" to search"
    when :remove
      "Remove tag \"#{tag.name}\" from search"
    when :all
      visibility = list&.search_visibility? ? " #{list.search_visibility?.to_s}" : ""

      "All#{visibility} bookmarks"
    when :any_visibility
      if list&.type != :all
        case list.search_visibility?
        when :public
          "Include private bookmarks"
        when :private
          "Include public bookmarks"
        end
      else
        "All bookmarks"
      end
    when :untagged
      "Untagged bookmarks"
    when :public
      "Public bookmarks only"
    when :private
      "Private bookmarks only"
    end
  end

  def tag_search_class(tag)
    tag.search_match? ? "search_remove" : "search_add"
  end
end
