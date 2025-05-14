class AddVisibilityToBookmark < ActiveRecord::Migration[6.1]
  def change
    reversible do |change|
      change.up do
        add_column :bookmarks, :visibility, :integer, null: false, default: 0

        Bookmark.where(private: true).update_all("visibility=1")

        remove_index :bookmarks, [:created_at, :id],
          name: "index_bookmarks_on_created_at_and_id_where_public"
        remove_column :bookmarks, :private, :boolean

        add_index :bookmarks, [:created_at, :id],
          order: {created_at: :desc, id: :asc},
          where: "#{connection.quote_column_name(:visibility)} = #{connection.quote(0)}",
          name: "index_bookmarks_on_created_at_and_id_where_public"
        add_index :bookmarks, [:created_at, :id],
          order: {created_at: :desc, id: :asc},
          where: "#{connection.quote_column_name(:visibility)} = #{connection.quote(1)}",
          name: "index_bookmarks_on_created_at_and_id_where_private"
        add_index :bookmarks, [:created_at, :id],
          order: {created_at: :desc, id: :asc},
          where: "#{connection.quote_column_name(:visibility)} = #{connection.quote(2)}",
          name: "index_bookmarks_on_created_at_and_id_where_secret"
        add_index :bookmarks, [:created_at, :id],
          order: {created_at: :desc, id: :asc},
          where: "#{connection.quote_column_name(:visibility)} != #{connection.quote(2)}",
          name: "index_bookmarks_on_created_at_and_id_where_not_secret"
      end

      change.down do
        remove_index :bookmarks, [:created_at, :id],
          name: "index_bookmarks_on_created_at_and_id_where_public"
        remove_index :bookmarks, [:created_at, :id],
          name: "index_bookmarks_on_created_at_and_id_where_private"
        remove_index :bookmarks, [:created_at, :id],
          name: "index_bookmarks_on_created_at_and_id_where_secret"
        remove_index :bookmarks, [:created_at, :id],
          name: "index_bookmarks_on_created_at_and_id_where_not_secret"

        add_column :bookmarks, :private, :boolean, null: false, default: false
        add_index :bookmarks, [:created_at, :id],
          order: {created_at: :desc, id: :asc},
          where: "#{connection.quote_column_name(:private)} = #{connection.quote(false)}",
          name: "index_bookmarks_on_created_at_and_id_where_public"

        Bookmark.where(visibility: "public").update_all("private=false")
        Bookmark.where.not(visibility: "public").update_all("private=true")

        remove_column :bookmarks, :visibility
      end
    end
  end
end
