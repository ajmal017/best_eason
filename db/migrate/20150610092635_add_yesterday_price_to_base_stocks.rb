class AddYesterdayPriceToBaseStocks < ActiveRecord::Migration
    
  def change
    # 昨收价同redis里面的previous_close相同
    add_column :base_stocks, :yesterday_price, :decimal, precision: 16, scale: 3
  end

end
