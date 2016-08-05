class StockIndex < Redis::HashKey

  include Singleton

  REDIS_KEY = 'cache:stock_indexes'
  SORT_KEYS = [:index, :change, :percent]

  def initialize
    super REDIS_KEY
  end

  def self.all
    instance.all.inject({}) do |result, row|
      result[row[0].to_sym] = parse(row[1])
      result
    end
  end

  def self.notify
    EventQueue::TopStockIndex.publish(::StockIndex.all)
  end

  def self.parse(str)
    Hash[SORT_KEYS.zip(str.split('|'))]
  end

end