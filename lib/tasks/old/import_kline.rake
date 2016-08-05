namespace :caishuo do
  desc 'import klines from quotes first time'
  task :import_kline => :environment do 
    BaseStock.find_each do |base_stock|

      week_rets = []
      base_stock.quotes.asc_date.group_by{ |x| x.send("week_flag") }.collect do |_, quote_list|
        week_rets << Kline.new(Kline.attrs_with(quote_list, 'week'))
      end
      Kline.import(week_rets)
      puts base_stock.id.to_s + '周K数据导入完成'


      month_rets = []
      base_stock.quotes.asc_date.group_by{ |x| x.send("month_flag") }.collect do |_, quote_list|
        month_rets << Kline.new(Kline.attrs_with(quote_list, 'month'))
      end

      Kline.import(month_rets)
      puts base_stock.id.to_s + '月K数据导入完成'

    end

  end
end
