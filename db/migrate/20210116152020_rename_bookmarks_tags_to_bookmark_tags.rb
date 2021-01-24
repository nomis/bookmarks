# SPDX-FileCopyrightText: 2021 Simon Arlott
# SPDX-License-Identifier: AGPL-3.0-or-later

class RenameBookmarksTagsToBookmarkTags < ActiveRecord::Migration[6.1]
  def change
    rename_table :bookmarks_tags, :bookmark_tags
  end
end
