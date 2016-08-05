class AddLastLoginAtToTradingAccounts < ActiveRecord::Migration
  def change
    add_column :trading_accounts, :last_login_at, :datetime
  end
end
