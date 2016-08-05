class MD::Data::LeaderStockAlter
  include Mongoid::Document
  include Mongoid::Timestamps

  store_in collection: "leader_stock_alters"

  field :base_stock_id, type: Integer
  field :symbol
  field :cname
  # 股份金额
  field :value, type: Float
  # 股份数额(股)
  field :shares, type: Integer
  # 增减持均价
  field :average_price, type: Float


  def pretty_json
    {
      id: base_stock_id,
      name: cname,
      type: 'stock',
      symbol: symbol
    }
  end

  
end
