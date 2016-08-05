module BasketCalculater
  extend ActiveSupport::Concern

  included do |klass|
    klass.send :include, InstanceMethods
    klass.extend ClassMethods

    # 热度等级
    include Redis::Objects
    counter :hot_rank, :start => 20  #热度等级 20 40 60 80 100
  end

  module InstanceMethods

    # 定时任务计算回报率
    def calculate_returns
      calculate_one_day_return
      calculate_days_return("one_month_return", 1.month)
      calculate_days_return("one_year_return", 1.year)
      self.update(total_return: calculate_return_from_start_on)
    end

    def return_from_start_on
      self.total_return || 0
    end

    # 购买一只股票最少价格
    def price_buy_any_stock
      basket_stocks.includes(:stock).select{|bs| bs.adjusted_weight > 0}.map{|bs| bs.stock.min_buy_money / bs.adjusted_weight}.max
    end

    # 每支股票预计购买只数
    def stock_est_shares
      budget = price_buy_any_stock

      basket_stocks.includes(:stock).inject({}) do |ret, bs|
        ret.merge! bs.stock => ((budget * bs.adjusted_weight / bs.stock.min_buy_money).round * bs.stock.get_board_lot rescue 0) # todo:ceil?
      end
    end

    # 最少花费
    def minimum_amount
      stock_est_shares.map{|stock, num| (stock.realtime_price * num).to_d }.sum 
    end

    # 重新计算主题权重
    def est_weights
      amount = minimum_amount
      weights = stock_est_shares.map do |stock, num|
        [stock.id, (stock.realtime_price * num / amount).round(4)]
      end
      Hash[weights]
    end

    def est_order_details_attributes
      order_detail_attributes = []
      weights = self.est_weights
      self.stock_est_shares.each do |stock, stock_shares|
        order_detail_attributes << {stock_id: stock.id, symbol: stock.symbol, com_name: stock.com_name, 
                                    weight: weights[stock.id]*100, stock_shares: stock_shares, 
                                    stock_price: stock.realtime_price, board_lot: stock.get_board_lot, 
                                    ib_symbol: stock.ib_symbol, exchange: stock.exchange}
      end
      order_detail_attributes
    end

    def update_orders_statistics
      buyed_orders = self.orders.buyed
      buyed_orders_count = buyed_orders.count
      buyed_orders_total_money = buyed_orders.map(&:real_cost).sum
      self.update(:orders_count => buyed_orders_count, :orders_total_money => buyed_orders_total_money)
    end

    def daily_return(date)
      self.basket_indices.by_date(date).first.try(:index) || self.simulation_daily_return(date)
    end

    def simulation_daily_return(date)
      tickers = self.ori_stock_symbol_weights
      tickers = self.symbol_weights if tickers.blank?
      work_date = ClosedDay.get_work_day(date, self.market)
      BasketIndex::Simulate.indices(tickers, work_date, work_date).to_h[work_date.to_s(:db)]
    end
    
    def cal_return_from(cal_date)
      cal_date = ClosedDay.get_work_day(cal_date, self.market)
      today_index = BasketIndex.lastest_basket_index(self.id).try(:index)
      latest_days_index = BasketIndex.get_index_by(self.id, cal_date) || 1000
      latest_days_index.blank? ? nil : (today_index/latest_days_index - 1)*100 rescue 0
    end

    def set_hot_score
      update_column(:hot_score, popularity)
    end

    private

    def calculate_days_return(db_field, return_days)
      date = Exchange::Base.by_area(market).prev_latest_market_date
      return false if !ClosedDay.is_workday?(date, market)
      today_index = BasketIndex.get_index_near_date(self.id, date)
      latest_days_index = BasketIndex.get_index_near_date(self.id, date - return_days)
      if latest_days_index.blank?
        days_return = nil
      else
        days_return = (today_index/latest_days_index - 1)*100 rescue 0
      end
      self.update_attribute(db_field.to_sym, days_return)
    end

    def calculate_one_day_return
      date = Exchange::Base.by_area(market).prev_latest_market_date
      today_index = BasketIndex.get_index_by(id, date)
      if today_index.blank?
        date = ClosedDay.get_work_day(date - 1, market)
        today_index = BasketIndex.get_index_by(id, date)
      end
      last_day = ClosedDay.get_work_day(date - 1, market)
      last_day_index = BasketIndex.get_index_by(id, last_day) || 1000
      ret = (today_index/last_day_index - 1)*100 rescue 0
      self.update(one_day_return: ret)
    end

    def calculate_return_from_start_on
      latest_day_index = latest_basket_index.try(:index) || 1000
      (latest_day_index/1000 - 1)*100 rescue 0
    end

    # 热度计算
    def popularity
      score = 100 * orders_count + 30 * follows_count + 10 * (opinions.bullished.count - opinions.bearished.count) + 8 * comments_count.to_i + views_count
      order = Math.log2([score.abs, 1].max)
      sign = score/score.abs rescue 0
      (order + updated_at.to_i * sign / 216000).round(5)
    end

  end


  module ClassMethods

    def minimum_amount_by(symbol_weight_hash)
      symbol_weight_hash = symbol_weight_hash.select{|symbol, weight| weight.to_f > 0}.map{|symbol, weight| [symbol.downcase, weight.to_f]}.to_h
      stocks_hash = BaseStock.where(symbol: symbol_weight_hash.keys).map{|s| [s.symbol.downcase, s]}.to_h
      price_buy_any_stock = symbol_weight_hash.map{|symbol, weight| stocks_hash[symbol].min_buy_money / weight rescue 0}.max
      symbol_weight_hash.map do |symbol, weight|
        (price_buy_any_stock * weight/ stocks_hash[symbol].min_buy_money).round * stocks_hash[symbol].get_board_lot * stocks_hash[symbol].realtime_price rescue 0
      end.sum
    end
    
    #计算热度等级
    def set_baskets_hot_ranks
      baskets = Basket.normal.public_finished.sort_by(&:hot_score).reverse
      grade_thresholds = [0, 0.05, 0.2, 0.4, 0.7, 1].map{|w| (w*baskets.count)}
      grouped_minmax = grade_thresholds[0..4].zip(grade_thresholds[1..5]).reverse
      baskets.each_with_index do |basket, b_index|
        grouped_minmax.each_with_index do |minmax, g_index|
          if (minmax[0]..minmax[1]).include?(b_index+1)
            basket.original.hot_rank.value = (g_index+1)*20
          end
        end
      end
    end

  end

end