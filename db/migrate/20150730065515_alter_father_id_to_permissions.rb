class AlterFatherIdToPermissions < ActiveRecord::Migration
  def change
  	change_column :permissions, :father_id, :integer, :default => 0
  end
end