# rubocop:disable all
class AddCiBuildsAndProjectsIndexes < ActiveRecord::Migration
  def change
    add_index :ci_projects, :doggohub_id
    add_index :ci_projects, :shared_runners_enabled

    add_index :ci_builds, :type
    add_index :ci_builds, :status
  end
end
