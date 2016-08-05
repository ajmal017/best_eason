class AddResourceToAdminLog < ActiveRecord::Migration
  def change
    add_column :admin_logs, :resource, :string
  end
end
