class AddStafferIdToPermission < ActiveRecord::Migration
  def change
  	add_column :permissions, :staffer_id, :integer
  	change_column :permissions, :staffer_id, :integer, :default => 0
  end
end