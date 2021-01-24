class BookmarkTag < ApplicationRecord
  belongs_to :bookmark
  belongs_to :tag

  def self.for_bookmarks_with_tags(tags)
    tags.inject(BookmarkTag) do |query, tag|
      query.where(bookmark_id: BookmarkTag.select(:bookmark_id).where(tag_id: tag))
    end
  end
end
