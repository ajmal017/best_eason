# 开市时检测用户在之前非交易时间的最后一个调仓是否可以正常执行
# 正常则按开盘价格
# 如遇涨停跌停，则退回上一交易时间版本
class ReadjustBasketsWorker
  @queue = :readjust_basket
  
  def self.perform(market)
    date = Exchange::Base.by_area(market).today
    return true unless ClosedDay.is_workday?(date, market)
    today_start_time, today_end_time = Exchange::Base.by_area(market).trade_time_range(date)
    # 开市1分钟后开始执行的定时任务，下面判断主要是判断us的夏令时、冬令时切换
    return true if Time.now < today_start_time
    last_workday = ClosedDay.get_work_day(date-1, market)
    last_day_start_time, last_day_end_time = Exchange::Base.by_area(market).trade_time_range(last_workday)

    bids = Basket.normal_history.where("created_at >= ? and created_at <= ?", last_day_end_time, today_start_time)
             .select("distinct original_id").map(&:original_id)
    bids.each do |basket_id|
      Resque.enqueue(ReadjustBasketWorker, basket_id)
    end

    # Basket.normal.where(market: market).select(:id).find_each do |basket|
    #   Resque.enqueue(ReadjustBasketWorker, basket.id)
    # end
  end
end