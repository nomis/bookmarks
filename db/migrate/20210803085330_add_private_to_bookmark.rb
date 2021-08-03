class AddPrivateToBookmark < ActiveRecord::Migration[6.1]
  def change
    add_column :bookmarks, :private, :boolean, null: false, default: false
  end
end
