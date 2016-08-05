class AddUniqueIndexToAccountValueArchives < ActiveRecord::Migration
  def change
    add_index :account_value_archives, [:user_id, :archive_date], unique: true
  end
end
