class CreateBookmarks < ActiveRecord::Migration[6.1]
  def change
    create_table :bookmarks do |t|
      t.string :title
      t.text :uri

      t.timestamps
    end
  end
end
