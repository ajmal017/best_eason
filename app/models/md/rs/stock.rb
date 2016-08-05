class MD::RS::Stock
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  store_in collection: "md_rs_stocks", database: Setting.md_data_db

  attr_accessor :symbol, :c_name, :trading_halt

  field :base_stock_id, type: Integer
  field :last, type: Float
  field :change_from_previous_close, type: Float
  field :percent_change_from_previous_close, type: Float
  field :volume, type: Float
  field :low, type: Float
  field :high, type: Float
  field :low52_weeks, type: Float
  field :high52_weeks, type: Float
  field :trade_time, type: DateTime
  field :market
  field :rt_logs, type: Array
  field :total_value_trade, type: Float
  field :market_capitalization, type: Float
  field :pe_ratio

  index({ base_stock_id: 1 }, { unique: true})

  index({base_stock_id: 1, market: 1})

  alias_attribute :realtime_price, :last
  alias_attribute :change_percent, :percent_change_from_previous_close
  alias_attribute :lastest_volume, :volume

  CURRENCY_MAPPINGS = {cn: "cny", hk: "hkd", us: "usd"}

  # 目前自选股使用
  def pretty_json
    as_json(
      only: [:change_from_previous_close, :total_value_trade, :base_stock_id],
      methods: [:realtime_price, :change_percent, :currency, :adj_market_capitalization]
    ).merge(lastest_volume: pretty_lastest_volume)
  end

  # 发生大批量数据时最好外部获取usd_rate
  def usd_rate
    @usd_rate ||= Currency::Cache.transform(currency, 'usd')
  end

  def currency
    CURRENCY_MAPPINGS[market.to_sym]
  end

  def adj_market_capitalization
    if is_cn?
      market_capitalization.to_f.zero? ? "--" : market_capitalization.to_f
    else
      market_capitalization.to_s.try(:to_number) rescue 0
    end
  end

  # 转换为以“亿”为单位的描述
  def market_capitalization_by_c_yi_unit(has_unit = false)
    adj_market_capitalization.to_f.zero? ? "--" : adj_market_capitalization.to_s.to_c_yi_unit(has_unit)
  end

  def pretty_lastest_volume
    is_cn? ? lastest_volume.to_i/100 : lastest_volume
  end

  def adj_pe_ratio
    pe_ratio.blank? || pe_ratio.to_f.zero? ? "--" : pe_ratio.to_f.round(2)
  end

  def is_cn?
    market == "cn"
  end
end