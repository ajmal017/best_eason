class ChangeUniqueIndexToAccountValueArchives < ActiveRecord::Migration
  def change
    remove_index :account_value_archives, name: 'unique_index_for_account_value_archives'
    
    # user_id兼容老数据
    add_index :account_value_archives, [:user_id, :trading_account_id, :key, :currency, :archive_date], name: 'unique_index_for_account_value_archives', :unique => true
  end
end
