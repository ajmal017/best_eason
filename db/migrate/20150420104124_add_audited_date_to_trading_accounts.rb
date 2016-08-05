class AddAuditedDateToTradingAccounts < ActiveRecord::Migration
  def change
    add_column :trading_accounts, :audited_date, :date
    add_column :trading_accounts, :actived_date, :date
  end
end
