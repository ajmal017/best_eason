namespace :dasai_datas do
  desc "大赛数据"
  task :statistics => :environment do
    FileUtils.makedirs(Rails.root.join("public/dasai"))
    start_time = Time.parse("2015-05-11 09:30:00")
    end_time = Time.parse("2015-05-22 15:00:00")

    statistic_1(start_time, end_time)
    statistic_2(start_time, end_time)
    statistic_3
    statistic_4(start_time, end_time)
    statistic_5(start_time, end_time)
    statistic_6(start_time, end_time)
    statistic_7(start_time, end_time)
    statistic_8(start_time, end_time)
    statistic_9
    statistic_10
    statistic_11
  end

  #一、调入最多，涨跌幅 (所有组合中，调入stock次数排名前20，涨跌幅: 11-22日收盘 涨跌)
  def statistic_1(start_time, end_time)
    stock_infos = adjusted_stock_infos(start_time, end_time, [1,3])
    save_stock_infos_to_csv(stock_infos, "1")
    puts "1"
  end

  #二、调出最多，涨跌幅 ( 同一)
  def statistic_2(start_time, end_time)
    stock_infos = adjusted_stock_infos(start_time, end_time, [2,4])
    save_stock_infos_to_csv(stock_infos, "2")
    puts "2"
  end

  def adjusted_stock_infos(start_time, end_time, actions, basket_ids = nil, limit = 20)
    logs = BasketAdjustment.calculable.where("basket_adjustments.created_at >= ? and basket_adjustments.created_at <= ?", start_time, end_time)
      .joins(:basket_adjust_logs).where(basket_adjust_logs: {action: actions}).where("basket_adjust_logs.stock_id is not null")
      .joins(:original_basket).where(baskets: {market: "cn", contest: true})
    logs = logs.where(baskets: {id: basket_ids}) if basket_ids.present?
    logs.group("basket_adjust_logs.stock_id").order("count(basket_adjust_logs.stock_id) desc")
      .select("basket_adjust_logs.stock_id, count(basket_adjust_logs.stock_id) as total").limit(limit)
      .map{|log| [log.stock_id, log.total]}
  end

  #三、多少盈利，多少亏损，总的平均收益, 前50名的平均收益
  def statistic_3
    profit_infos = BasketRank.contest_1_top(600)
    profit_count = profit_infos.select{|k,v| v>=0}.size
    loss_count = profit_infos.select{|k,v| v<0}.size
    avg_ret = profit_infos.map{|k,v| v}.sum.to_f/profit_infos.size
    top_50_infos = BasketRank.contest_1_top(50)
    top_50_avg_ret = top_50_infos.map{|k,v| v}.sum.to_f/top_50_infos.size
    CSV.open("public/dasai/3.csv", "wb") do |csv|
      csv << ["多少盈利", profit_count]
      csv << ["多少亏损", loss_count]
      csv << ["总的平均收益", avg_ret]
      csv << ["前50名的平均收益", top_50_avg_ret]
    end
    puts "3"
  end


  #四、前50名的调入调出(同一)
  def statistic_4(start_time, end_time)
    basket_ids = BasketRank.contest_1_top(50).keys
    stock_infos = adjusted_stock_infos(start_time, end_time, [1,3], basket_ids, 1000)
    save_stock_infos_to_csv(stock_infos, "4_in")
    puts "4-1 "

    stock_infos = adjusted_stock_infos(start_time, end_time, [2,4], basket_ids, 1000)
    save_stock_infos_to_csv(stock_infos, "4_out")
    puts "4_2 "
  end

  def save_stock_infos_to_csv(stock_infos, filename)
    CSV.open("public/dasai/#{filename}.csv", "wb") do |csv|
      csv << ["symbol", "名称", "次数", "股票涨跌%"]
      stock_infos.each do |stock_id, count|
        stock = BaseStock.find(stock_id)
        rtn = stock.return_between(Date.parse("2015-05-08"), Date.parse("2015-05-22"))
        csv << [stock.symbol, stock.com_name, count, rtn]
      end
    end
  end

  #五、调仓最频繁的，调仓后胜率最高的（两个人, 胜率待议）
  def statistic_5(start_time, end_time)
    bids = BasketAdjustment.calculable.where("basket_adjustments.created_at >= ? and basket_adjustments.created_at <= ?", start_time, end_time)
      .joins(:original_basket).where(baskets: {market: "cn", contest: true})
      .group("original_basket_id").order("count(original_basket_id) desc").limit(2)
      .select(:original_basket_id).map(&:original_basket_id)
    baskets = Basket.where(id: bids)
    CSV.open("public/dasai/5.csv", "wb") do |csv|
      csv << ["调仓最频繁的"]
      csv << ["组合id", "创建人", "创建人id"]
      baskets.each do |basket|
        csv << [basket.id, basket.author.username, basket.author_id]
      end
    end
    puts "5"
  end

  #六、用户持仓最多的股票前五(top 50用户，持仓时间统计)
  def statistic_6(start_time, end_time)
    stock_times = Hash.new(0)
    basket_ids = BasketRank.contest_1_top(50).keys
    basket_ids.each do |bid|
      history_baskets = Basket.normal_history.where(original_id: bid).order(:created_at).includes(:basket_stocks)
        .select{|bh| bh.created_at>=start_time && bh.created_at<= end_time && bh.created_at.hour.in?(9..15) && bh.created_at.strftime("%H%M") >= "0931"}
      history_baskets.each_with_index do |basket, index|
        basket.basket_stocks.select{|x| x.weight>0}.each do |bs|
          if index.zero?
            time = basket.created_at - start_time
          elsif index == history_baskets.size
            time = end_time - basket.created_at
          else
            prev_history_basket = history_baskets[index-1]
            if prev_history_basket.basket_stocks.select{|x| x.weight>0 && x.stock_id == bs.stock_id}.present?
              time = basket.created_at - prev_history_basket.created_at
            else
              time = 0
            end
          end
          stock_times[bs.stock_id] = stock_times[bs.stock_id] + time
        end
      end
    end
    CSV.open("public/dasai/6.csv", "wb") do |csv|
      stock_times.each do |stock_id, seconds|
        csv << [BaseStock.find(stock_id).symbol, seconds]
      end
    end
    puts "6"
  end

  #七、大家都在几点调仓(all, 比如 9:00-9:30)
  def statistic_7(start_time, end_time)
    created_times = BasketAdjustment.where(state: [0,1,4,5]).where("basket_adjustments.created_at >= ? and basket_adjustments.created_at <= ?", start_time, end_time)
                    .joins(:original_basket).where(baskets: {market: "cn", contest: true})
                    .select(:created_at).map{|x| x.created_at}.map{|t| [t.hour, t.min]}
                    .group_by{|h,_| h}
    CSV.open("public/dasai/7.csv", "wb") do |csv|
      (0..23).each do |hour|
        [[0, 29], [30, 60]].each do |min_minute, max_minute|
          count = created_times[hour].to_a.select{|h,m| m>=min_minute && m<=max_minute}.size
          csv << ["#{hour}:#{min_minute}-#{hour}:#{max_minute}", count]
        end
      end
    end
    puts "7"
  end

  #八、用户平均调仓次数，前50
  def statistic_8(start_time, end_time)
    basket_ids = BasketRank.contest_1_top(50).keys
    totals = BasketAdjustment.calculable.where("basket_adjustments.created_at >= ? and basket_adjustments.created_at <= ?", start_time, end_time)
      .joins(:original_basket).where(baskets: {market: "cn", contest: true, id: basket_ids})
      .group("original_basket_id").select("count(original_basket_id) as total").map(&:total)
    avg_count = totals.sum.to_f/totals.size
    CSV.open("public/dasai/8.csv", "wb") do |csv|
      csv << ["用户前50名平均调仓次数", avg_count]
    end
    puts "8"
  end

  #九、调仓频繁是否等同于收益最高 (去掉)
  def statistic_9
  end

  #十、收益跑赢大盘的、创业板 (人数，list)
  # 给出所有人的list
  def statistic_10
    CSV.open("public/dasai/10.csv", "wb") do |csv|
      csv << ["组合id", "创建者", "创建者id", "回报"]
      BasketRank.contest_1_top(600).each do |basket_id, rtn|
        basket = Basket.find(basket_id)
        csv << [basket.id, basket.author.username, basket.author_id, rtn]
      end
    end
    puts "10"
  end

  #十一、sharp比例：每天平均回报/每天平均波动 (算法待定)
  def statistic_11
  end

end