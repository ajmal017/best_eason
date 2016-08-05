# 未复权历史价格
class HistoricalQuotePrice < ActiveRecord::Base
  def self.prices_by(stock_ids, date)
    where(base_stock_id: stock_ids, date: date).select(:base_stock_id, :last)
      .pluck(:base_stock_id, :last).to_h
  end

  def self.price_by(stock_id, date)
    find_by(base_stock_id: stock_id, date: date).last rescue 0
  end

  # 未复权价格与复权后价格对比得出一个参考比例
  # 测试环境trade_time有非交易日的，所以需要矫正日期
  def self.price_ratio(stock_id, price_date, historical_klass)
    unless Rails.env.production?
      price_date = ClosedDay.get_work_day(price_date, BaseStock.find(stock_id).market)
    end
    ori_price = HistoricalQuotePrice.price_by(stock_id, price_date)
    adjusted_price = historical_klass.price_by(stock_id, price_date)
    return 1 if adjusted_price.zero?

    ori_price / adjusted_price.to_f
  end
end
