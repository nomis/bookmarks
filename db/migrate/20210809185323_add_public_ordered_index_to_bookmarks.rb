class AddPublicOrderedIndexToBookmarks < ActiveRecord::Migration[6.1]
  def change
    add_index :bookmarks, [:created_at, :id],
      order: {created_at: :desc, id: :asc},
      where: "#{connection.quote_column_name(:private)} = #{connection.quote(false)}",
      name: "index_bookmarks_on_created_at_and_id_where_public"
  end
end
