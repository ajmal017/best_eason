class CreateAccountAnalyses < ActiveRecord::Migration
  def change
    create_table :account_analyses do |t|
      t.references :user
      t.references :trading_account
      t.integer :year
      t.float :profit
      t.integer :buy_count
      t.integer :sell_count
      t.float :avg_month_trade
      t.string :focus_industry, comment: "重点关注行业"
      t.integer :cleared_stock_count, comment: "清仓股票"
      t.float :win_rate, comment: "胜率"
      t.integer :earned_stocks_count, comment: "挣钱股票"
      t.integer :lossed_stocks_count, comment: "赔钱股票"
      t.float :avg_holded_days, comment: "平均持有时间"
      t.string :holding_terms, comment: "短线、中长线、长线"
      t.string :stock_earn, comment: "盈亏额最高、最低"
      t.string :stock_holded_days, comment: "持有时间最长、最短"
      t.string :stock_spend, comment: "投入金额最多、最少"
      t.float :total_buyed, comment: "累计买入"
      t.float :total_selled, comment: "累计卖出"
      t.string :industries, comment: "投资分布：行业"
      t.string :market_distribution, comment: "主板、创业板"
      t.string :orientation, comment: "投资方向"
      t.string :concern, comment: "投资关注"

      t.timestamps
    end

    add_index :account_analyses, [:trading_account_id, :year]
  end
end
