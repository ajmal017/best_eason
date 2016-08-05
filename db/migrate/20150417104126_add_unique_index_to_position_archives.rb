class AddUniqueIndexToPositionArchives < ActiveRecord::Migration
  def change
    remove_index :position_archives, name: 'unique_index_position_archives'
    
    add_index :position_archives, [:user_id, :trading_account_id, :instance_id, :base_stock_id, :archive_date], name: 'unique_index_position_archives', unique: true
  end
end
