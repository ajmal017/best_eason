class MD::Data::Macd
  include Mongoid::Document
  include Mongoid::Timestamps

  store_in collection: "filter_macds"

  field :base_stock_id, type: Integer
  field :symbol
  field :cname
  field :area
  # 金叉 死叉
  field :direction
  field :date
  # 最新
  field :latest, type: Boolean

  index({base_stock_id: 1}, {background: true})
  index({date: -1}, {background: true})

  scope :latest, -> { where(latest: true) }
  scope :buy, -> { where(direction: :buy) }
  scope :sell, -> { where(direction: :sell) }

  def pretty_json
    {
      id: base_stock_id,
      name: cname,
      symbol: symbol,
      type: 'stock'
    }
  end
end
