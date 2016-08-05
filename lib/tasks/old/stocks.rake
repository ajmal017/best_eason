namespace :stocks do
  desc "清除base_stocks字段c_name中纯英文字符"
  task :clean_c_name => :environment do
    arr = []
    BaseStock.find_each do |bs|
      next if bs.c_name.blank?
      r = /[^a-z0-9]+/i.match(bs.c_name.strip.gsub(" ", ""))
      if r.blank?
        bs.c_name = nil
        bs.save
      end
    end
  end

  desc "humanize公司的英文名称"
  task :humanize_com_name => :environment do
    arr = []
    BaseStock.find_each do |bs|
      bs.name = bs.name.split(" ").map{|x| x.humanize}.join(" ")
      bs.c_name = bs.c_name.split(" ").map{|x| x.humanize}.join(" ") if bs.c_name.present?
      bs.save
    end
  end

  desc "stock改为单表继承初始化"
  task :init_base_stock_type => :environment do
    BaseStock::EXCHANGE_AREAS.each do |exchange, area|
      class_name = case area
                   when :cn
                     "Stock::Cn"
                   when :hk
                     "Stock::Hk"
                   when :us
                     "Stock::Us"
                   end
      BaseStock.where(exchange: exchange).update_all(type: class_name)
    end
    BaseStock.sp500.update(type: "Stock::Us")
    BaseStock.hs.update(type: "Stock::Hk", exchange: "SEHK")
    # BaseStock.csi300.update(type: "Stock::Cn")
    BaseStock.where(symbol: ["000001.SH", "399001.SZ", "000300.SH"]).update_all(type: "Stock::Cn")
    BaseStock.where(symbol: ["000001.SH", "000300.SH"]).update_all(exchange: "SSE")
    BaseStock.where(symbol: ["399001.SZ"]).update_all(exchange: "SZSE")
    puts "-----  All end  -----"
  end

  desc "初始化A股票的各个回报率及各个成交量字段"
  task :cal_stock_returns_of_a => :environment do
    BaseStock.find_each do |stock|
      stock.cal_stock_returns
      puts stock.id
    end

    Stock::Cn.find_in_batches(batch_size: 1000) do |base_stocks|
      stocks = base_stocks.map { |bs| BaseStock.new(bs.trend!.merge(id: bs.id)) }
      BaseStock.import_trend(stocks)
    end
    puts "all end"
  end

  desc "add cash stock # no use"
  task :add_cash_stock => :environment do
    attrs = {
      name: "现金", symbol: "cash", qualified: false, stock_type: "cash", 
      normal: false, type: "Stock::Cash"
    }
    BaseStock.create!(attrs)
  end
end