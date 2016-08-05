class MD::Data::PlateTradingFlow
  include Mongoid::Document
  include Mongoid::Timestamps

  store_in collection: "plate_trading_flows"

  # 名称
  field :name
  # 涨跌幅
  field :change_percent, type: Float
  # 主力净流入
  field :main_value, type: Float
  # 主力净流入百分比
  field :main_percent, type: Float
  # 最大净流入股票
  embeds_one :led, class_name: 'MD::Data::Stock'

  accepts_nested_attributes_for :led

  scope :latest, -> { where(latest: true) }


  def pretty_json
    {
      name: name,
      type: 'plate',
      change_percent: change_percent,
      main_value: main_value,
      main_percent: main_percent,
      stock_name: led.cname,
      stock_id: led.id,
      stock_symbol: led.symbol
    }
  end


end
