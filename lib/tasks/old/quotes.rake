namespace :quotes do
  desc "初始化抓取之前的历史数据，及计算几个汇率"
  task :init_history_quotes_for_foreign_exchanges => :environment do
    # 同步美元-港元、美元-人民币历史汇率
    ids = BaseStock.where(:symbol => ["HKD=X", "CNY=X"]).map(&:id)
    Yahoo::Historical::Base.new(ids).sync

    # 计算其他几个汇率的历史数据
    (5.years.ago.to_date..Date.today).each do |date|
      Quote.calculate_foreign_exchange(date)
    end
  end

  desc "初始化intraday_quotes中的local_date"
  task :intraday_quotes => :environment do
    IntradayQuote.where(market: "us").find_each do |iq|
      iq.update(local_date: iq.trade_time.in_time_zone('Eastern Time (US & Canada)').to_date)
    end

    IntradayQuote.where(market: "hk").find_each do |iq|
      iq.update(local_date: iq.trade_time.to_date)
    end
  end
end