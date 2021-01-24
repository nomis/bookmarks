module BookmarkHelper
  def link_to_search_by_tags(tag)
    link_to(
      tag.name,
      tag_search_href(tag),
      title: tag_search_title(tag),
      rel: "nofollow",
      style: tag.search_match? ? "search_remove" : "search_add"
    )
  end

  private

  def tag_search_href(tag)
    if tag.search_toggle_type == :none
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
end
