module Xignite
  class Retry

    def initialize(base_stock_id, xignite_symbol)
      @base_stock_id = base_stock_id
      @xignite_symbol = xignite_symbol
    end
    
    def retry
      if retry_times < 5
        incr_retry_count!
        
        Resque.enqueue(XigniteHistoricalSync, @xignite_symbol)
      else
        $xignite_logger.error("historical_sync error!!!" + @xignite_symbol)
      end
    end

    def retry_times
      $redis.get(redis_key).to_i
    end

    def incr_retry_count!
      $redis.incr(redis_key) && $redis.expire(redis_key, 3.hour)
    end

    def redis_key
      "xignite_historical_retry:" + @base_stock_id.to_s
    end

  end
end
