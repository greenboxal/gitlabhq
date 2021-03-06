# rubocop:disable all
class RemoveOauthTokensFromUsers < ActiveRecord::Migration
  def change
    remove_column :users, :github_access_token, :string
    remove_column :users, :doggohub_access_token, :string
    remove_column :users, :bitbucket_access_token, :string
    remove_column :users, :bitbucket_access_token_secret, :string
  end
end
