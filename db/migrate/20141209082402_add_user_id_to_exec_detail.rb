class AddUserIdToExecDetail < ActiveRecord::Migration
  def change
    add_column :exec_details, :user_id, :integer
    add_column :exec_details, :stock_id, :integer
    
    add_index :exec_details, :user_id
    add_index :exec_details, :stock_id
  end
end
