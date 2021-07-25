class AddIpToVersions < ActiveRecord::Migration[6.1]
  def change
    add_column :versions, :ip, :string
  end
end
