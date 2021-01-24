class BookmarkFacade
  def initialize(bookmark, search_tags = Set.new)
    @bookmark = bookmark
    @search_tags = search_tags
  end

  def to_param
    @bookmark.to_param
  end

  def title
    @bookmark.title
  end

  def uri
    @bookmark.uri
  end

  def tags
    @tag_facades ||= @bookmark.tags.sort_by(&:name).map { |tag| TagFacade.new(tag, @search_tags) }
  end
end
