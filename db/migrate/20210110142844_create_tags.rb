# SPDX-FileCopyrightText: 2021 Simon Arlott
# SPDX-License-Identifier: AGPL-3.0-or-later

class CreateTags < ActiveRecord::Migration[6.1]
  def change
    create_table :tags do |t|
      t.string :key, null: false
      t.string :name, null: false

      t.timestamps
    end

    add_index :tags, [:key], unique: true
  end
end
