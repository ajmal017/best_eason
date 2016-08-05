namespace :user_day_properties do
  desc "修复错误数据"
  task :fix_market_value => :environment do
    date = '2015-08-03'
    stock_ids = PositionArchive.where(archive_date: date, market: 'cn').select("distinct(base_stock_id)").map(&:base_stock_id)
    
    close_prices = {}
    stock_ids.each do |stock_id|
      close_prices.merge!(stock_id => HistoricalQuoteCn.where(base_stock_id: stock_id).where("date <= ?", date).order(date: :desc).first.try(:last).to_f)
    end
    
    PositionArchive.where(archive_date: date, market: 'cn').find_each do |pa|
      close_price = close_prices[pa.base_stock_id]
      puts "#{pa.base_stock_id} #{close_price}"
      pa.update(close_price: close_price) if close_price
    end

    TradingAccountPassword.active.find_each do |account|
      puts account.id
      property = UserDayProperty.find_by(trading_account_id: account.id, date: date)
      next if property.nil?

      market_value = PositionArchive.where(archive_date: date, trading_account_id: account.id).map{|x| x.shares.to_i * x.close_price}.sum.to_f
      total = market_value + property.total_cash
      property.update(total: total)
    end

  end

  desc "修改收益"
  task :fix_profit => :environment do
    TradingAccountPassword.active.find_each do |account|
      puts account.id
      UserProfit.sync(account, Date.parse('2015-08-03'))
    end 
  end
end
