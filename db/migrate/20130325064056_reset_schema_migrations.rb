class ResetSchemaMigrations < ActiveRecord::Migration
  def up
    ActiveRecord::SchemaMigration.where(["version > ?", 200003250640560]).update_all("version =floor( version/10)")
  end
end
