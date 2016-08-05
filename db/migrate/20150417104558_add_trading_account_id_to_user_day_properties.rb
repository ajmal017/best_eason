class AddTradingAccountIdToUserDayProperties < ActiveRecord::Migration
  def change
    add_column :user_day_properties, :trading_account_id, :integer
    add_index :user_day_properties, [:trading_account_id, :user_id, :date], name: 'unique_index_for_user_properties', unique: true
  end
end
