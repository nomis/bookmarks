class AddUserAgentToVersions < ActiveRecord::Migration[6.1]
  def change
    add_column :versions, :user_agent, :string
  end
end
