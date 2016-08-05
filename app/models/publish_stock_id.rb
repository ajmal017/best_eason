# 记录需要sync实时数据的id, 根据时间戳判断3分钟内的push实时信息
class PublishStockId
  REDIS_KEY = "publish_stock_ids"
  EXPIRE_MINUTE = 3

  class << self

    def add(stock_id, ts = nil)
      ts ||= Time.now.to_i
      $redis.zadd(ids_queue_key, ts, stock_id)
    end

    def add_batch(stock_ids, ts = Time.now.to_i)
      arr = stock_ids.map{|sid| [ts, sid]}
      $redis.zadd(ids_queue_key, arr)
    end

    def stock_ids
      $redis.zrangebyscore(ids_queue_key, EXPIRE_MINUTE.minutes.ago.to_i, "+inf")
    end

    def stock_symbols
      $redis.zrangebyscore(symbol_queue_key, EXPIRE_MINUTE.minutes.ago.to_i, "+inf")
    end

    def delete_expired
      delete_expired_ids
      delete_expired_symbols
    end

    def add_by_stock(stock)
      markets = Exchange::Util.get_trading_areas
      self.add(stock.id) if markets.include?(stock.market_area)
      add_symbol_by_stock(stock, markets)
    end

    def add_symbol_by_stock(stock, markets = nil)
      markets ||= Exchange::Util.get_trading_areas
      add_to_symbol_queue(stock.xignite_symbol) if stock.can_add_to_realtime_queue? && markets.include?(stock.market_area)
    end

    private
    def ids_queue_key
      REDIS_KEY + ":ids"
    end

    def symbol_queue_key
      REDIS_KEY + ":symbols"
    end

    def add_to_symbol_queue(symbol)
      $redis.zadd(symbol_queue_key, Time.now.to_i, symbol)
    end
    
    def delete_expired_ids
      $redis.zremrangebyscore(ids_queue_key, "-inf", EXPIRE_MINUTE.minutes.ago.to_i)
    end

    def delete_expired_symbols
      $redis.zremrangebyscore(symbol_queue_key, "-inf", EXPIRE_MINUTE.minutes.ago.to_i)
    end
  end
end