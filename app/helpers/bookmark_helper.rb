module BookmarkHelper
  def link_to_search_by_tags(tag, matching)
    search_tags =
      if matching.include?(tag.id)
        matching ^ [tag.id]
      else
        matching | [tag.id]
      end

    if search_tags.empty?
      search_href = root_path
      search_title = "All bookmarks"
    else
      search_href = search_by_tags_path(tags: search_tags.sort(&NaturalSort).join(","))
      search_title =
        if matching.empty?
          'Search by tag "' + tag.name + '"'
        elsif matching.include? tag.id
          'Remove tag "' + tag.name + '" from search'
        else
          'Add tag "' + tag.name + '" to search'
        end
    end

    link_to(
      tag.name,
      search_href,
      title: search_title,
      rel: "nofollow",
      style: matching.include?(tag.id) ? "search_remove" : "search_add"
    )
  end
end
