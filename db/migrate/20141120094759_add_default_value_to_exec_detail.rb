class AddDefaultValueToExecDetail < ActiveRecord::Migration
  def change
    change_column :exec_details, :processed, :boolean, default: false
  end
end
