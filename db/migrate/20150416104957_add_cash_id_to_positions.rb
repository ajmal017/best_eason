class AddCashIdToPositions < ActiveRecord::Migration
  
  def change
    add_column :positions, :cash_id, :string
    add_column :positions, :trading_account_id, :integer

    add_index :positions, :cash_id
    add_index :positions, :trading_account_id
  end

end
