class AddUniquenessConstraintToBookmark < ActiveRecord::Migration[6.1]
  def change
    add_index :bookmarks, :uri, unique: true
  end
end
