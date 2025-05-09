class AddVisibilityToUser < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :visibility, :integer, null: false, default: 0
  end
end
