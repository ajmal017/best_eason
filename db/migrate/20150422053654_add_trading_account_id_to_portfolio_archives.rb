class AddTradingAccountIdToPortfolioArchives < ActiveRecord::Migration

  def change
    add_column :portfolio_archives, :trading_account_id, :integer
    add_index :portfolio_archives, :trading_account_id
  end

end
