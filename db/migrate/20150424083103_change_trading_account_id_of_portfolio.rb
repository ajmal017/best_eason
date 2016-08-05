class ChangeTradingAccountIdOfPortfolio < ActiveRecord::Migration
  def change
    change_column :portfolios, :trading_account_id, :integer
  end
end
