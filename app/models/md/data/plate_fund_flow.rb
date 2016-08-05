class MD::Data::PlateFundFlow
  include Mongoid::Document
  include Mongoid::Timestamps

  store_in collection: "filter_plate_fund_flows"

  field :base_stock_id
  field :symbol
  # 名称
  field :name
  
  # 涨跌幅
  field :change_percent,    type: Float
  
  # 超大单/大单/中单/小单 流入流出
  field :huge_buy_value,    type: Float
  field :huge_sell_value,   type: Float
  field :large_buy_value,   type: Float
  field :large_sell_value,  type: Float
  field :middle_buy_value,  type: Float
  field :middle_sell_value, type: Float
  field :small_buy_value,   type: Float
  field :small_sell_value,  type: Float

  # 主力净流入值
  field :main_net_inflow_value, type: Float
  # 主力净流入百分比
  field :main_net_inflow_percent, type: Float
  
  # 最大净流入个股
  embeds_one :led, class_name: 'MD::Data::Stock'

  index({base_stock_id: 1}, {background: true})
  index({name: 1}, {background: true})
  
  accepts_nested_attributes_for :led

  scope :sort, ->{ order(change_percent: :desc) }
 
  def pretty_json
    {
      name: name,
      type: 'plate',
      change_percent: change_percent,
      plate_stock_id: base_stock_id,
      main_value: main_net_inflow_value,
      main_percent: main_net_inflow_percent,
      stock_name: led.try(:cname),
      stock_id: led.try(:id),
      stock_symbol: led.try(:symbol)
    }
  end

end
