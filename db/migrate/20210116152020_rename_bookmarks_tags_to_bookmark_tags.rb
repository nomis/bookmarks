class RenameBookmarksTagsToBookmarkTags < ActiveRecord::Migration[6.1]
  def change
    rename_table :bookmarks_tags, :bookmark_tags
  end
end
