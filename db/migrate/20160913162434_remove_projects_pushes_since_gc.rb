# See http://doc.doggohub.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for DoggoHub.

class RemoveProjectsPushesSinceGc < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = true
  DOWNTIME_REASON = 'This migration removes an existing column'

  disable_ddl_transaction!

  def up
    remove_column :projects, :pushes_since_gc
  end

  def down
    add_column_with_default :projects, :pushes_since_gc, :integer, default: 0
  end
end
