class AddVisibilityToBookmark < ActiveRecord::Migration[6.1]
  def change
    reversible do |change|
      change.up do
        add_column :bookmarks, :visibility, :integer, null: false, default: 0

        execute <<-SQL
          UPDATE bookmarks
          SET visibility = (CASE WHEN private = true THEN 1 ELSE 0 END)
        SQL

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

        execute <<-SQL
          UPDATE bookmarks
          SET private = (CASE WHEN visibility = 0 THEN false ELSE true END)
        SQL

        remove_column :bookmarks, :visibility
      end
    end
  end
end
