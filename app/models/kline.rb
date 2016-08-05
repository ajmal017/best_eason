class Kline < ActiveRecord::Base

  # 当天交易日K线数据
  def self.rt_quote_json(base_stock)
    trading_date = base_stock.trading_date

    attrs = {
      open: base_stock.open.to_f, high: base_stock.high.to_f, low: base_stock.low.to_f, close: base_stock.realtime_price.to_f, volume: base_stock.volume,
      start_date: trading_date.to_s(:db), end_date: trading_date.to_s(:db), date: (trading_date.to_time + 8.hours).to_i * 1000
    }

    ma_cache = KlineMaCache.find_by(base_stock_id: base_stock.id, category: KlineMaCache.categories[:daily])
    %W{ma5 ma10 ma20 ma30}.each do |field|
      if ma_cache
        value = ma_cache.send(field)
        attrs[field] = (value.first + base_stock.realtime_price).fdiv(value.last + 1).round(2)
      else
        attrs[field] = base_stock.realtime_price
      end
    end

    attrs.to_json
  rescue Exception => e
    {}.to_json
  end

  # 目前网站日K不走STOCK行情项目
  def self.daily_quotes(base_stock, opts={})
    # 未上市股票直接返回空
    return "[]" if base_stock.trading_unlisted? || base_stock.third_board?

    json_quotes = $azure.get_blob("quote", base_stock.id.to_s).last rescue ""
    # 如果日K的日期小于当前股票的交易日期,则添加一条K线
    last_index = json_quotes.rindex("{", -1)

    if last_index && base_stock.trading_date
      last_quote = JSON.parse(json_quotes[last_index..-2])
      if base_stock.trading_normal? && (Date.parse(last_quote["end_date"]) < base_stock.trading_date) && !foreign_index_ids.include?(base_stock.id) && (base_stock.open > 0)
        json_quotes.insert(-2, ",#{rt_quote_json(base_stock)}")
      end
    else
      json_quotes = "[#{rt_quote_json(base_stock)}]"
    end

    return json_quotes
  end

  # 港股每股指数ids
  def self.foreign_index_ids
    [7950, 7951, 7952, 8179]
  end
  
  # 手机端日K,目前不调用行情项目
  def self.mobile_daily_quotes(base_stock, opts = {})
    json_quotes = daily_quotes(base_stock)
    
    # 根据start_date和end_date筛选
    if opts[:start_date] || opts[:end_date]
      quotes = Oj.load(json_quotes)

      if opts[:start_date].present?
        quotes = quotes.select{ |q| q["start_date"] >= opts[:start_date] } 
      end

      if opts[:end_date].present?
        quotes = quotes.select{ |q| q["start_date"] <= opts[:end_date] } 
      end

      json_quotes = Oj.dump(quotes)
    end

    return json_quotes
  end

end
