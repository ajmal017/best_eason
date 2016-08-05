module Yahoo
  module Historical
    class Base
      # 并发请求数量
      NUM_PER_SYNC = 5

      attr_accessor :stocks

      def initialize(ids)
        @stocks = BaseStock.by_ids(ids).map{|x| Stock.new(base_id: x.id, symbol: x.ticker) }
      end

      def sync
        symbol_stocks = Yahoo::Grab.get(@stocks)
        
        symbol_stocks.map do |stock, his_stocks|
          next if his_stocks.blank?

          next stock.retry unless stock.last_workday_synced?(his_stocks.last.date)
          
          next his_stocks.first.resync if (first_stock = his_stocks.first) && first_stock.resync?
          
          stock.store(stock.calculate_index(his_stocks))
          $finance_logger.info("#{stock.try(:symbol)} 同步数量 #{his_stocks.count}")
        end
      end
    end

    class Stock
      include Yahoo::Retry
      include ValidateAttributes

      # 默认同步日期
      DEFAULT_DATE = '2009-01-01'

      # 初始指数
      DEFAULT_INDEX = 1000.0

      BASE_URL = "http://itable.finance.yahoo.com/table.csv"

      DECIMAL_FIELDS = %w(open high low close adj_close)

      attr_accessor :base_id, :symbol, :recent_date, :end_date, :date, :open, :high, :low, :close, :volume, :adj_close, :index, :validate

      def initialize(opts = {})
        %w(base_id symbol date volume open high low close adj_close).each do |field|
          opts[field.to_sym] = opts[field.to_sym].try(:to_d) if DECIMAL_FIELDS.include?(field)
          instance_variable_set("@#{field}", opts[field.to_sym])
        end
        super(opts) if opts[:validate]
      end

      # 股票redis key
      def historical_key
        'us_historical_' + @base_id.to_s
      end

      # 开始同步日期
      def recent_date
        Quote.where(base_id: @base_id).order(date: :desc).first.date.to_s(:db) rescue DEFAULT_DATE
      end

      # 调整之后的收盘价
      def recent_adj_close
        Quote.find_by(base_id: @base_id, date: self.recent_date).try(:adj_close)
      end

      # 最近指数
      def recent_index
        (Quote.find_by(base_id: @base_id, date: self.recent_date).try(:index) || DEFAULT_INDEX).to_f
      end

      # 是否从默认日期同步
      def from_default?
        self.recent_date == DEFAULT_DATE
      end

      # 如果adj_close有变化，需要重新取得所有历史数据
      def resync?
        return false if recent_adj_close.nil?
        adj_close.to_f.round(2) != recent_adj_close.to_f.round(2)
      end

      def resync
        logging && delete_dirty_data
        Resque.enqueue(SyncHistoricalStock, @base_id)
      end

      def logging
        $finance_logger.warn("resyncing... #{symbol}, #{self.recent_date}, #{self.date}, #{self.recent_adj_close}, #{self.adj_close}")
        QuoteResyncLog.create(symbol: symbol, base_id: @base_id, old_adj_close: recent_adj_close, new_adj_close: adj_close)
      end

      def delete_dirty_data
        Quote.where(base_id: @base_id).delete_all
        #$redis.del(historical_key)
      end

      # 计算历史数据指数
      def calculate_index(stocks)
        index = recent_index
        prev_close = stocks.first.try(:adj_close)
        stocks.each do |stock|
          index = index * stock.adj_close.to_f / prev_close.to_f
          prev_close = stock.adj_close
          stock.index = index.round(13).to_d
        end
        stocks
      end

      def store(stocks)
        multi_mysql_save(stocks)
        #multi_redis_save(stocks)
      end

      def multi_mysql_save(stocks)
        return import_quotes(stocks) if from_default? && stocks.present?
        stocks.each{|stock| stock.mysql_save }
      end

      # 并发导入数据
      def import_quotes(quotes)
        imports = quotes.map{|x| [x.symbol, x.date, x.open, x.high, x.low, x.close, x.volume, x.adj_close, x.index, x.base_id]}
        fork do
          import_start_at = Time.now
          begin
            ret = Quote.import(%w(symbol date open high low close volume adj_close index base_id), imports, on_duplicate_key_update: [:adj_close, :open, :high, :low, :close, :volume, :index])
          rescue Exception => e
            $finance_logger.error("导入出错 imports: #{imports.inspect}, message: #{e.message}, backtrace: #{e.backtrace}")
          else
            $finance_logger.info("导入结束 import: #{imports.first.inspect}, time: #{Time.now - import_start_at}s, result: #{ret.inspect}")
          end
        end 
      end

      def mysql_save
        Quote.find_or_initialize_by(base_id: base_id, date: date).update(instance_values)
      rescue Exception => e
        $finance_logger.error(e.message)
      end

      def multi_redis_save(stocks)
        attrs = Hash[stocks.map{|x| [x.date, {adj_close: x.adj_close, index: x.index}] }]
        $cache.multi_hwrite(historical_key, attrs) if attrs.present?
      end

      def request_url
        "#{BASE_URL}?s=#{URI.escape(@symbol)}&g=d".tap do |url| 
          if recent_date = Date.parse(self.recent_date.to_s)
            url << "&a=#{recent_date.month-1}"
            url << "&b=#{recent_date.mday}"
            url << "&c=#{recent_date.year}" 
          end

          if end_date = Date.today
            url << "&d=#{end_date.month-1}"
            url << "&e=#{end_date.mday}"
            url << "&f=#{end_date.year.to_s}"
          end
        end
      end

      # 最后一个工作日是否同步下来
      def last_workday_synced?(last_date)
        market_area = BaseStock.find_by(self.base_id).market_area
        ClosedDay.get_work_day(Date.yesterday, market_area).to_s(:db) == last_date
      end
    end
  end
end

