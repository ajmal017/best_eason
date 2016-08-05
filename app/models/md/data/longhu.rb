class MD::Data::Longhu
  include Mongoid::Document
  include Mongoid::Timestamps

  store_in collection: "longhus"

  field :base_stock_id, type: Integer
  field :symbol
  field :cname
  field :date
  # 上榜原因
  field :reason
  field :reason_type, type: Integer

  REASON_TYPES = {
    1 => "当日涨幅偏离值达7%的证券",
    2 => "当日跌幅偏离值达7%的证券",
    3 => "当日换手率达到20%的证券",
    4 => "当日价格振幅达到15%的证券",
    5 => "连续三日涨幅累计超20%",
    6 => "连续三日跌幅累计超20%"
  }

  scope :latest, -> { where(latest: true) }


  def pretty_json
    {
      id: base_stock_id,
      name: cname,
      type: 'stock',
      symbol: symbol
    }
  end

end
