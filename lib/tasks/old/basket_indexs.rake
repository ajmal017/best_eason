namespace :basket_indexs do
  desc "从按日期+symbol存储的stock index，冗余到以symbol为key的，date为field的新数据集"
  task :init_all_stock_index_together => :environment do
    BaseStock.searchable_stocks.find_each do |stock|
      BasketIndex.sync_stock_all_indices_to_redundancy_datas(stock.id)
      # 1836.downto(1).each do |day|
      #   date = Date.today - day
      #   date_str = date.strftime('%Y-%m-%d')
      #   Resque.enqueue(SyncStockIndexToRedundancyData, stock.id, date_str)
      # end

      puts stock.id
    end
  end

  desc "每天定时：跑每个basket的index"
  task :calculate_basket_index_everyday => :environment do
    Basket.completed_and_archived.find_each do |basket|
      next if basket.stocks.blank?
      BasketIndex.record_index_yesterday(basket.id)
    end
  end

  desc "跑每个basket的index，只用于测试阶段重跑index用，正式上线只需要跑每天的定时"
  task :calculate_basket_index_everyday => :environment do
    raise "error"
    Basket.public_finished.find_each do |basket|
      next if basket.stocks.blank?
      (basket.start_date..(Date.today-1)).each do |date|
        BasketIndex.record_index(basket.id, date)
      end
      puts basket.id
    end
  end

  desc "init index_without_cash 20150403"
  task :init_index_without_cash => :environment do
    ActiveRecord::Base.connection.execute("update basket_indices set index_without_cash = `index`")
  end
end