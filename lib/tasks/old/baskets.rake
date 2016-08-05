namespace :baskets do
  desc "20150326 提前几个basket一个月"
  task :advance_start_on_20150326 => :environment do
    ids = [3138, 3122, 3146, 3119]
    baskets = Basket.where(id: ids)
    baskets.each do |b|
      history_baskets = Basket::History.where(original_id: b.id).where("latest_history_id is null")
      raise "error: #{b.id} historys invalid" if history_baskets.count > 1
      earlist_history_basket = history_baskets.first

      start_time = b.start_on - 1.month
      b.update(start_on: start_time, created_at: start_time)
      earlist_history_basket.update(start_on: start_time, created_at: start_time)

      b.reload
      b.basket_indices.delete_all
      BasketWeightLog.where(:basket_id => b.id).delete_all

      (b.start_date..(Date.today-1)).each do |date|
        BasketIndex.record_index(b.id, date)
        puts date
      end
      b.calculate_returns
      b.set_bullish_percent
      b.set_hot_score
      puts b.id
    end
  end

  desc "重新跑信息，不更改日期"
  task :rerun_all_index => :environment do
    Basket.finished.where(type: ["Basket::Normal", "Basket::Custom"]).find_each do |b|
      puts b.id
      # b.basket_indices.delete_all
      # BasketWeightLog.where(:basket_id => b.id).delete_all
      
      (b.start_date..(Date.today-1)).each do |date|
        BasketIndex.record_index(b.id, date)
        puts date
      end
      b.calculate_returns
      puts b.id
    end
  end

  desc "导出baskets信息"
  task :export_basket_stock_shares => :environment do
    CSV.open("stocks.csv", "wb") do |csv|
      Basket.public_finished.each do |b|
        stock_shares = b.stock_est_shares
        total = stock_shares.map{|stock, share| share}.sum
        stock_shares.each_with_index do |stock_share, index|
          stock, share = stock_share
          if index == stock_shares.size-1
            csv << [b.title, stock.symbol, share, total, b.minimum_amount]
          else
            csv << [b.title, stock.symbol, share]
          end
        end
      end
    end
  end

  desc "audit状态转移到basket_audit表中，状态改变"
  task :revert_audit_to_complete_state => :environment do
    Basket.where(state: 3).update_all(state: 4)
  end

  desc "初始化market字段"
  task :init_baskets_market => :environment do
    Basket.includes(basket_stocks: [:stock]).each do |basket|
      basket.update(market: basket.basket_stocks.first.stock.market_area) if basket.basket_stocks.present?
    end
    puts "end"
  end

  desc "test"
  task :test_error => :environment do
    ids = []
    Basket.finished.each do |b|
      begin
        b.original.tags
      rescue
        ids << b.id
      end
    end
  end

  desc "初始化错误的start_on"
  task :reset_wrong_start_on => :environment do
    raise "error"
    ids = %w(162 24 116 191 149 108 189 41 209 371 212 208 253 216 212 22)
    Basket.where(id: ids).each do |b|
      first_date = b.first_basket_index.date
      time = first_date.to_date + 8.hours
      if b.original_id == b.id
        b.update(start_on: time, created_at: time)
      else
        b.original.update(start_on: time, created_at: time)
        Basket.where("original_id = ?", b.original_id).update_all(start_on: time)
      end
    end

    puts "*"*99
    Basket::Normal.where("original_id is null").finished.each do |b|
      if b.start_date != b.created_at.to_date
        b.update(created_at: b.start_on)
        puts b.id
      end
    end
    puts "end"
  end

  desc "检查创建当天调仓的组合"
  task :check_baskets_of_adjust_at_start_date => :environment do
    raise "error"
    ids = []
    Basket.normal_history.where("original_id is null or id = original_id").each do |b|
      next if b.start_on.blank?
      start_day_baskets = Basket.normal.where.not(id: b.id).where("original_id is not null and id <> original_id")
                                .where("created_at > ? and created_at < ?", b.start_on, b.start_date.at_end_of_day)
      ids << b.id if start_day_baskets.count > 0
    end
    puts ids

    ids = [491, 532, 686, 877, 880, 906, 918, 924, 936, 937, 943]
    Basket.where(id: ids).map(&:newest_version).each do |b|
      b.reload
      b.basket_indices.destroy_all
      BasketWeightLog.where(:basket_id => b.id).delete_all

      (b.start_date..(Date.today-1)).each do |date|
        BasketIndex.record_index(b.id, date)
        puts date
      end
      b.calculate_returns
      b.set_bullish_percent
      b.set_hot_score
      puts b.id
    end
  end
end