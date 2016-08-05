class AddLatestHistoryIdToBaskets < ActiveRecord::Migration
  def change
    add_column :baskets, :latest_history_id, :integer

    add_index :baskets, :latest_history_id
  end
end