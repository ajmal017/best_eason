class AlterNameToRole < ActiveRecord::Migration
  def change
  	change_column :roles, :name, :string, :varchar => 50
  end
end