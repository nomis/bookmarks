class CreateBookmarkTags < ActiveRecord::Migration[6.1]
  def change
    create_table "bookmarks_tags", id: false do |t|
      t.references :bookmark, null: false, foreign_key: true
      t.references :tag, null: false, foreign_key: true

      t.timestamps
    end
  end
end
