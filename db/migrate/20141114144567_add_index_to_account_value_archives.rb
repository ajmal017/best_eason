class AddIndexToAccountValueArchives < ActiveRecord::Migration
  def change
    add_index :account_value_archives, [:user_id, :key, :currency, :archive_date], name: 'unique_index_for_account_value_archives', :unique => true
  end
end
