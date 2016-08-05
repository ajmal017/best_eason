namespace :xignite do
  desc 'init realtime data from xignite'
  task :xignite_init => :environment do
    
    puts "init data"
    BaseStock.where("ticker like '% %' or ticker is null or ticker = ''").each do |bs| 
      bs.update(ticker: '')
    end

    BaseStock.find_each do |bs|
      bs.save
    end
    
    raise "含有非法数据" if BaseStock.where("ticker like '% %' or xignite_symbol like '% %'").count > 0

    max_date = BaseStock.maximum(:date)
    hide_symbols = ['HBANP', '4338.HK']
       
    BaseStock.where("date >= ?", max_date - 2.days).where.not(symbol: hide_symbols).update_all(normal: true)
    # 3日以上数据设置为不合法
    BaseStock.where("date < ?", max_date - 2.days).update_all(normal: false)
    # OLD以及OLD.HK结尾的数据不合法
    BaseStock.where("symbol like '%\.OLD' or symbol like '%\.OLD\.HK'").update_all(normal: false)
    # HBANP 4338.HK 隐藏
    BaseStock.where(symbol: hide_symbols).update_all(normal: false)
    # ib_id不合法
    BaseStock.where(ib_id: nil).update_all(normal: false)
    # DATE为NIL的设置不合法
    BaseStock.where(date: nil).update_all(normal: false)
    # 不合法SYMBOLS
    BaseStock.where(symbol: hide_symbols).update_all(normal: false)
    
    puts "合法数据#{BaseStock.trading_normal.count}"

    # 抓取XIGNITE实时数据
    BaseStock.trading_normal.select(:xignite_symbol).pluck(:xignite_symbol).in_groups_of(300).each do |symbols|
      puts "syncing realtime...#{symbols.count}"
      Xignite::RealTime::Base.new(symbols.compact).sync
    end

    # 抓取Fundament数据
    BaseStock.trading_normal.select(:ticker).pluck(:ticker).in_groups_of(300).each do |tickers|
      puts "syncing fundament...#{tickers.count}"
      Yahoo::Fundament::Base.new(tickers).sync
    end
    
    # 同步CURRENCY数据
    Yahoo::Currency::Base.new.sync
    puts "完成"

        
  end
end
