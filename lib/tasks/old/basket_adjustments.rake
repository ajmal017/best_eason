namespace :basket_adjustments do

  desc "history 旧数据时间校正到交易时间段"
  task :adjust_history_time => :environment do
    Basket.normal_history.where("parent_id is not null and created_at < '2015-05-08 17:30:00'").each do |basket|
      time = basket.market == "us" ? (basket.created_at-5.hour) : basket.created_at
      workday = ClosedDay.get_work_day(time.to_date, basket.market)
      if workday == time.to_date
        trading_start_at, trading_end_at = basket.trading_time_range(workday)
        if basket.created_at > trading_end_at
          basket.update(created_at: trading_end_at - 60.seconds)
        end
      else
        workday = ClosedDay.get_work_day_after(time.to_date, basket.market)
        trading_start_at, trading_end_at = basket.trading_time_range(workday)
        if basket.created_at < trading_start_at
          basket.update(created_at: trading_start_at + 60.seconds)
        end
      end
    end

    puts "next"
    # 旧数据realtime_weight_from使用weight_from
    ActiveRecord::Base.connection.execute("update basket_adjust_logs set realtime_weight_from = weight_from")

    puts "next"
    date = Date.parse("2015-05-08")
    Basket.where(type: ["Basket::Normal", "Basket::Custom"]).completed_and_archived.find_each do |basket|
      BasketIndex.record_index(basket.id, date)
      basket.calculate_returns
      puts basket.id
    end
  end

  task :fix_datas => :environment do
    bids = [3163, 4191, 1497, 4662, 4887, 4912, 5001, 4725, 5134, 5240, 5290, 4956, 962, 5139, 4928, 5229, 5538, 4629, 4725, 5538, 5001, 5240, 4371, 4813, 5297, 1944, 1809, 5136, 4841, 4371, 5136, 6074, 4614, 1787, 4841, 6089, 6093, 4813]
    bids.each do |bid|
      puts bid
      basket = Basket.find_by_id(bid)
      next unless basket
      puts ReadjustBasketWorker.perform(basket.original_id)
    end

    puts "next"
    BasketAdjustment.where(date: "2015-05-11", state: 2).each do |ba|
      puts "adjustment #{ba.id}"
      ba.basket_adjust_logs.except_cash.each do |log|
        log.update(stock_price: log.stock.open)
      end
      ba.update(created_at: Time.parse("2015-05-11 09:31:00"))
    end

    puts "next"
    bids = Basket.normal.finished.where("start_on < ?", Date.parse("2015-05-07 23:59:59")).select(:id).map(&:id)
    exist_bids = BasketIndex.where(basket_id: bids, date: "2015-05-07").select(:basket_id).map(&:basket_id)
    Basket.where(id: (bids - exist_bids)).each do |b|
      puts b.id
      (b.start_date..Date.parse("2015-05-08")).each do |date|
        BasketIndex.record_index(b.id, date)
      end
    end

    puts "next"
    exclude_ids = [1381,1621,1967,3459,4704]
    basket_ids = Basket.normal.contest.where.not(id: exclude_ids).where("created_at<?", Time.parse("2015-05-08 15:00:00")).select(:id).map(&:id)
    BasketIndex.where(basket_id: basket_ids, date: "2015-05-08").update_all(index: 1000)

    puts "next-----"
    Basket.normal.finished.each do |b|
      puts b.id
      b.calculate_returns
    end
  end

  desc "矫正adjustment数据  非初始建仓日期"
  task :fix_adjust_logs => :environment do
    basket_id = 6089
    first_adjustment_id = 1464
    fixed_adjustment_id = 1482
    next_basket_id = 6333
    date = Date.parse("2015-05-12")
    last_workday = ClosedDay.get_work_day(date-1, basket.market)
    basket = Basket.find(basket_id)
    last_workday_weights = BasketWeightLog.stock_adjusted_weights(basket.id, last_workday)
    # stock_rets = BasketIndex::StockReturn.realtime_open_rets(last_workday_weights.keys)
    # realtime_weights = BasketIndex::RealtimeWeight.adjust_by(last_workday_weights, stock_rets)
    prev_day_snapshots = BasketStockSnapshot.where(basket_adjustment_id: first_adjustment_id).select(:stock_id, :weight).map{|x| [x.stock_id, x.weight]}.to_h
    cash_weight = 1 - (prev_day_snapshots.values.map{|w| w||0}.reduce(:+) || 0)
    next_basket_ori_weights = Basket.find(next_basket_id).stock_ori_weights
    adjustment = BasketAdjustment.find(fixed_adjustment_id)
    stock_ids = (prev_day_snapshots.keys + next_basket_ori_weights.keys).uniq
    adjustment.destroy_logs
    logs = BaseStock.where(id: stock_ids).map do |stock|
      weight = prev_day_snapshots[stock.id] || 0
      realtime_weight = last_workday_weights[stock.id] || 0
      open = HistoricalQuoteCn.where(base_stock_id: stock.id, date: date).last.open
      stock_info = {stock_price: open, change_percent: 0, weight: weight, realtime_weight: realtime_weight}
      BasketAdjustLog.generate(adjustment, stock, stock_info, next_basket_ori_weights[stock.id])
    end
    logs << BasketAdjustLog.generate(adjustment, nil, {weight: cash_weight, stock_price: 1}, next_basket_ori_weights[Stock::Cash.id])
    BasketAdjustLog.import(logs, validate: true)
    BasketIndex.record_index(basket.id, Date.parse("2015-05-13"))
    basket.calculate_returns
  end

  desc "矫正adjustment数据  初始建仓日期, prev_day_snapshots 为0"
  task :fix_adjust_logs_2 => :environment do
    basket_id = 6089
    fixed_adjustment_id = 1348
    next_basket_id = 6193
    date = Date.parse("2015-05-11")
    last_workday = ClosedDay.get_work_day(date-1, basket.market)
    basket = Basket.find(basket_id)
    realtime_weights = {}
    prev_day_snapshots = {}
    cash_weight = 1
    next_basket_ori_weights = Basket.find(next_basket_id).stock_ori_weights
    adjustment = BasketAdjustment.find(fixed_adjustment_id)
    stock_ids = (prev_day_snapshots.keys + next_basket_ori_weights.keys).uniq
    adjustment.destroy_logs
    logs = BaseStock.where(id: stock_ids).map do |stock|
      weight = prev_day_snapshots[stock.id] || 0
      realtime_weight = realtime_weights[stock.id] || 0
      open = HistoricalQuoteCn.where(base_stock_id: stock.id, date: date).last.open
      stock_info = {stock_price: open, change_percent: 0, weight: weight, realtime_weight: realtime_weight}
      BasketAdjustLog.generate(adjustment, stock, stock_info, next_basket_ori_weights[stock.id])
    end
    logs << BasketAdjustLog.generate(adjustment, nil, {weight: cash_weight, stock_price: 1}, next_basket_ori_weights[Stock::Cash.id])
    BasketAdjustLog.import(logs, validate: true)
    BasketIndex.record_index(basket.id, Date.parse("2015-05-11"))
    BasketIndex.record_index(basket.id, Date.parse("2015-05-12"))
    basket.calculate_returns
  end


  desc "处理线上违规的组合"
  task :process_basket_stocks_weights => :environment do
    basket_id = 4203
    stock_id = 11476
    basket = Basket.find(basket_id)
    bids = Basket.where(original_id: basket.id).map(&:id)
    bids.push(basket.id)
    BasketStock.where(basket_id: bids, stock_id: stock_id).update_all(weight: 0, adjusted_weight: 0, ori_weight: 0)
    ba_ids = BasketAdjustment.where(original_basket_id: basket.id).select(:id).map(&:id)
    BasketAdjustLog.where(basket_adjustment_id: ba_ids, stock_id: stock_id).update_all(action: 5, weight_from: 0, weight_to: 0, realtime_weight_from: 0)
    (basket.start_date..Date.parse("2015-05-14")).each do |date|
      BasketIndex.record_index(basket.id, date)
    end
    BasketIndex.where(basket_id: basket.id).where("date<='2015-05-08'").update_all(index: 1000)
    (Date.parse("2015-05-11")..Date.parse("2015-05-14")).each do |date|
      BasketIndex.record_index(basket.id, date)
    end
    basket.calculate_returns
  end

end