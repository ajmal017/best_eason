module Xignite
  module Historical
    class Base

      def initialize(symbol)
        @symbol = symbol
      end

      def sync
        quotes = Xignite::Strategy::Typhoeus.new(@symbol).run
        
        return quotes.first.resync if quotes.present? && quotes.first.adj_close_changed?

        quotes = Quote.calculate_index(quotes)
        
        Quote.save_to_mysql(quotes)
      end
      
    end

    class Quote
      # 默认同步日期
      DEFAULT_DATE = '2009-01-01'

      # 初始指数
      DEFAULT_INDEX = 1000.0

      FIELDS = %w(symbol base_stock_id last open high low volume date last_close change_from_open percent_change_from_open change_from_last_close percent_change_from_last_close index currency)
      
      DECIMAL_FIELDS = %w(open high low last last_close index)

      attr_accessor *FIELDS

      def initialize(opts = {})
        FIELDS.each do |attribute|
          opts[attribute] = opts[attribute].to_s.to_d if DECIMAL_FIELDS.include?(attribute)
          instance_variable_set("@#{attribute}", opts[attribute])
        end
        
        @date = Date.strptime(opts['date'], '%m/%d/%Y') rescue opts['date']

        adjust_illegal_percent_change_from_last_close if opts[:validate]
      end

      # 最后同步日期
      def recent_date
        HistoricalQuote.where(base_stock_id: @base_stock_id).order(date: :desc).first.date.to_s(:db) rescue DEFAULT_DATE
      end

      # 已经同步的最后一天指数
      def recent_index
        HistoricalQuote.where(base_stock_id: @base_stock_id).order(date: :desc).first.try(:index) || DEFAULT_INDEX
      end
      
      # 某一天的LAST PRICE
      def last_with(date)
        HistoricalQuote.find_by(base_stock_id: @base_stock_id, date: date).try(:last)
      end
      
      # 重新同步数据
      def resync
        logging
        delete_dirty_data

        Resque.enqueue(XigniteHistoricalSync, self.symbol)
      end

      def logging
        HistoricalQuoteResync.create(symbol: @symbol, base_stock_id: @base_stock_id, old_last: last_with(self.date), new_last: self.last)
        
        $xignite_logger.warn("resyncing...#{symbol}, #{self.date}, #{self.last}, #{last_with(self.date)}")
      end

      def delete_dirty_data
        HistoricalQuote.where(base_stock_id: @base_stock_id).delete_all
      end
      
      # LAST是否变化(上一个工作日价格存在 && 当前LAST不等于0 && LAST发生变化)
      def adj_close_changed?
        last_close_price = last_with(self.date)
        last_close_price.present? && !last.zero? && ( last.to_f.round(3) != last_close_price.try(:to_f).round(3) )
      end

      # 如果perent_change_from_last_close大于10000,认为非法
      def adjust_illegal_percent_change_from_last_close
        @percent_change_from_last_close = 0 if @percent_change_from_last_close >= 10000
      end

      # 计算历史数据指数
      def self.calculate_index(quotes)
        return [] if quotes.blank?
        
        quotes = reject_illegal_quotes(quotes) if quotes.first.last.zero?

        index, previous_close = quotes.first.recent_index, quotes.first.try(:last)
        quotes.each_with_index do |quote, i|
          quote = autofill_with(quote, quotes[i - 1], i) if quote.last.zero?
          
          index, previous_close = (index * quote.last.to_f / previous_close.to_f), quote.last
          
          quote.index = index.round(13).to_d
        end
        
        quotes
      end
      
      # 自动填充LAST为0的数据
      def self.autofill_with(quote, previous_quote, index)
        if index.zero?
          previous_quote = HistoricalQuote.where(base_stock_id: quote.base_stock_id).where("date < ?", quote.date).order(date: :desc).first
          return quote if previous_quote.nil?
        end

        %w(last open high low last_close).each {|field| quote.send( "#{field}=", previous_quote.last ) }
        quote.volume = 0
        quote
      end

      # 删除以0开始的前几天历史数据
      def self.reject_illegal_quotes(quotes)
        return quotes if HistoricalQuote.exists?(base_stock_id: quotes.first.base_stock_id)

        legal_index = quotes.each_with_index{|quote, index| break index if !quote.last.zero?}
        return quotes[legal_index..-1] if legal_index.is_a?(Integer)
        quotes
      end

      def self.save_to_mysql(quotes)
        return false if quotes.blank?
        HistoricalQuote.import(quotes.first.instance_values.keys, quotes.map{|x| x.instance_values.values }, validate: :false)
      rescue Exception => e
        $xignite_logger.error("import error!!! #{e.message}")
      end

    end
  end
end
