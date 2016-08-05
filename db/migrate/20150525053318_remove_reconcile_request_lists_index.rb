class RemoveReconcileRequestListsIndex < ActiveRecord::Migration
  def change
    remove_index :reconcile_request_lists, :user_id
  end
end
