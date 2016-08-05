module Yahoo
  module Retry
    extend ActiveSupport::Concern

    def self.included(klass)
      klass.send(:include, InstanceMethods)
    end

    module InstanceMethods

      def retry_key
        "historical_retry_times_" + base_id.to_s
      end

      def retry_times
        $redis.get(retry_key).to_i
      end

      def incr_retry_count!
        $redis.incr(retry_key) && $redis.expire(retry_key, 3.hour)
      end

      def retry
        if retry_times < 5
          incr_retry_count!
          Resque.enqueue(SyncHistoricalStock, base_id) unless unexist_symbol?
        else
          $finance_logger.error(symbol + '===抓取数据失败===')
          #Yahoo::HistoricalFailLog.create(base_id: base_id)
          
          # 如果是合法数据或者是已经购买的股票或者是主题里面包含的股票,则加入循环列表
          if stock_qualified?(base_id) || Position.exists?(base_stock_id: base_id) || BasketStock.exists?(stock_id: base_id)
            Yahoo::HistoricalRetry.create(symbol: symbol, base_stock_id: base_id, date: Date.today)
          end
        end
      end

      def stock_qualified?(base_stock_id)
        BaseStock.find(base_stock_id).qualified?
      end

      # 已经确认不存在的symbol
      def unexist_symbol?
        symbol.match(/\-P/).present?
      end
    end
  end
end
