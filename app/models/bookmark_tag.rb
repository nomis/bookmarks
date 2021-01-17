class BookmarkTag < ApplicationRecord
  belongs_to :bookmark
  belongs_to :tag

  def self.for_bookmarks_with_tags(tags)
    tags.reduce(BookmarkTag) { |query, tag| query.where(bookmark_id: BookmarkTag.select(:bookmark_id).where(tag_id: tag)) }
  end
end
