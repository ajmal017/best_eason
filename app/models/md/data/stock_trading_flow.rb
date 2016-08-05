# 今日个股主力净流入
# 今日个股主力净流出
class MD::Data::StockTradingFlow
  include Mongoid::Document
  include Mongoid::Timestamps

  store_in collection: "stock_trading_flows"

  field :base_stock_id, type: Integer
  field :symbol
  field :c_name
  # 主力净流入
  field :main_value, type: Float
  # 主力净流入百分比
  field :main_percent, type: Float
  # 更新日期
  field :date

  scope :latest, -> { where(latest: true) }


  def pretty_json
    {
      id: base_stock_id,
      name: c_name,
      symbol: symbol,
      type: 'stock'
    }
  end


end
