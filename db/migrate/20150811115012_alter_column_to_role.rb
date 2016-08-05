class AlterColumnToRole < ActiveRecord::Migration
  def change
  	remove_column :roles, :abbrev, :string
  	remove_column :roles, :position, :string
  	remove_column :roles, :staffers_count, :integer
  	remove_column :roles, :description, :string
  end
end
