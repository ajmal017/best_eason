class AddTradingAccountIdToPositionArchives < ActiveRecord::Migration
  
  def change
    add_column :position_archives, :trading_account_id, :integer
    add_column :position_archives, :cash_id, :string

    add_index :position_archives, :trading_account_id
    add_index :position_archives, :cash_id
  end

end
