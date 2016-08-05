class AddPtStatusToTradingAccounts < ActiveRecord::Migration
  def change
    add_column :trading_accounts, :extend_status, :integer
  end
end
