class AddTradingAccountIdToAccountValueArchives < ActiveRecord::Migration
  def change

    add_column :account_value_archives, :trading_account_id, :integer

    add_index :account_value_archives, :trading_account_id
  end
end
