class AddTradingAccountIdToPortfolios < ActiveRecord::Migration
  def change
    add_column :portfolios, :trading_account_id, :string
  end
end
