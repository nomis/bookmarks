class CreateBookmarks < ActiveRecord::Migration[6.1]
  def change
    create_table :bookmarks do |t|
      t.string :title, null: false
      t.text :uri, null: false

      t.timestamps
    end
  end
end
