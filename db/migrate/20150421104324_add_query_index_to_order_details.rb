class AddQueryIndexToOrderDetails < ActiveRecord::Migration
  def change
    # 组合批量盈亏查询索引
    add_index :order_details, [:trading_account_id, :instance_id, :trade_time], name: 'basket_profit_index'
    # 个股批量盈亏查询索引
    add_index :order_details, [:trading_account_id, :instance_id, :base_stock_id, :trade_time], name: 'stock_profit_index'
  end
end
