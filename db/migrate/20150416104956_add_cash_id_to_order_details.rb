class AddCashIdToOrderDetails < ActiveRecord::Migration

  def change
    add_column :order_details, :cash_id, :string
    add_column :order_details, :trading_account_id, :integer

    add_index :order_details, :trading_account_id
    add_index :order_details, :cash_id
  end

end
