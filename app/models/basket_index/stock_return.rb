class BasketIndex::StockReturn
  class << self

    def calculate(stock_ids, date, last_day, market_area)
      stocks_rets = {}
      stocks_indices = get_stocks_indices(stock_ids, [date, last_day], market_area)
      stock_ids.each do |stock_id|
        stocks_rets[stock_id] = calculate_stock_return(stock_id, stocks_indices[stock_id], date, last_day)
      end
      stocks_rets
    end

    def calculate_stock_return(stock_id, stock_indices, today_date, last_day_date)
      today_stock_index = stock_indices.try(:[], today_date.to_s(:db))
      last_day_stock_index = stock_indices.try(:[], last_day_date.to_s(:db))
      if today_stock_index.present? && last_day_stock_index.present?
        return today_stock_index.to_f/last_day_stock_index.to_f - 1
      else
        $basket_index_logger.info("miss_index #{Time.now.to_s} - stock_id:#{stock_id}")
        return 0
      end
    end

    # 实时return，实时指数计算使用
    def realtime_rets(stock_ids)
      stocks_return = {Stock::Cash.id => Stock::Cash.stock_return}
      BaseStock.where(id: stock_ids).each do |stock|
        stocks_return[stock.id] = stock.change_ratio
      end
      stocks_return
    end

    def realtime_open_rets(stock_ids)
      stocks_return = {Stock::Cash.id => Stock::Cash.stock_return}
      BaseStock.where(id: stock_ids).each do |stock|
        stocks_return[stock.id] = stock.open_change_ratio
      end
      stocks_return
    end

    # 取未复权过的数据
    def stocks_close_prices(stock_ids, date)
      HistoricalQuotePrice.prices_by(stock_ids, date)
    end

    def stocks_realtime_prices(stock_ids)
      BaseStock.where(id: stock_ids).map do |stock|
        [stock.id, stock.realtime_price]
      end.to_h
    end

    private

    def get_stocks_indices(stock_ids, dates, market_area)
      historical_quote_class(market_area).grouped_indices_by_dates(stock_ids, dates)
    end

    def historical_quote_class(market_area)
      market_area.to_s == "cn" ? HistoricalQuoteCn : HistoricalQuote
    end

  end
end