class AddVisibilityToUser < ActiveRecord::Migration[6.1]
  def change
    reversible do |change|
      change.up do
        add_column :users, :visibility, :integer, null: false, default: 0

        User.update_all("visibility=1")
      end

      change.down do
        remove_column :users, :visibility
      end
    end
  end
end
