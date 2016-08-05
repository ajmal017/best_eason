class MD::Data::Plate
  include Mongoid::Document
  include Mongoid::Timestamps

  store_in collection: "filter_plates"

  # 股票ID
  field :base_stock_id
  field :symbol
  # 名称
  field :name
  # 涨跌额
  field :change, type: Float
  # 涨跌幅
  field :change_percent, type: Float

  # 最大净流入股票
  embeds_one :led, class_name: 'MD::Data::Stock'

  accepts_nested_attributes_for :led

  scope :sort, ->{ desc(:change_percent) }

  def pretty_json
    {
      name: name,
      type: 'plate',
      change_percent: change_percent,
      plate_stock_id: base_stock_id,
      stock_name: led.try(:cname),
      stock_id: led.try(:id),
      stock_symbol: led.try(:symbol)
    }
  end
end
