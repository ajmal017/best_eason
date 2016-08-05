class AddDeletedUserIdToMessages < ActiveRecord::Migration
  def change
    add_column :messages, :deleted_user_id, :integer
  end
end
