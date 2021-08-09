class AddOrderedIndexToBookmarks < ActiveRecord::Migration[6.1]
  def change
    add_index :bookmarks, [:created_at, :id], order: {created_at: :desc, id: :asc}
  end
end
