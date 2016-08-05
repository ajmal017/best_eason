class AddTradingAccountIdToBasketRanks < ActiveRecord::Migration
  def change
    add_column :basket_ranks, :trading_account_id, :integer

    add_index :basket_ranks, :trading_account_id
  end
end
