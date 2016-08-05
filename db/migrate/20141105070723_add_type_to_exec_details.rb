class AddTypeToExecDetails < ActiveRecord::Migration
  def change
    add_column :exec_details, :type, :string
  end
end
