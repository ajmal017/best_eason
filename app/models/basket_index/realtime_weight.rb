class BasketIndex::RealtimeWeight
  class << self

    def adjust_by(weights, rets)
      return {} if weights.blank?
      
      formula_denominator = denominator(weights, rets)
      weights.map do |stock_id, weight|
        weights[stock_id] = ((1 + rets[stock_id].to_f)*weight/formula_denominator).to_d
      end
      last_stock_id = weights.select{|k,v| v>0}.keys.last
      return weights if last_stock_id.blank?

      weights[last_stock_id] = 1 - weights.values.sum + weights[last_stock_id]
      weights
    rescue Exception => e
      $basket_index_logger.error "realtime_weight: #{weights} ; #{rets}"
      raise e.message
    end

    def record_adjust_weights(basket, weights, date)
      low_accurate_weights = to_low_accurate(weights)
      BasketWeightLog.recreate_logs(weights, basket.id, date) if can_set_weight_logs?(basket, date)
      
      basket.set_adjusted_weights(weights, low_accurate_weights, date) if can_set_adjusted_weights?(basket, date)
    end

    private
    
    def denominator(weights, rets)
      weights.map{|stock_id, weight| (1 + rets[stock_id].to_f)*weight }.sum
    end

    # stock_weights 转换为保留3位小数的
    def to_low_accurate(weights)
      return {} if weights.blank? || weights.values.sum.zero?
      
      low_acc_weights = weights.map{|stock_id, weight| [stock_id, weight.round(3)]}.to_h
      last_stock_id = low_acc_weights.select{|k,v| v>0}.keys.last
      low_acc_weights[last_stock_id] = 1 - low_acc_weights.values.sum + low_acc_weights[last_stock_id]
      low_acc_weights
    end

    def can_set_weight_logs?(basket, date)
      end_time = end_trade_time(basket, date)
      basket.start_on && basket.start_on <= end_time 
    end

    def can_set_adjusted_weights?(basket, date)
      end_time = end_trade_time(basket, date)
      basket_count_after_end_time = Basket.normal_history.where(original_id: basket.id).where("created_at > ?", end_time).count
      basket_count_after_end_time.zero?
    end

    def end_trade_time(basket, date)
      Exchange::Base.by_area(basket.market).trade_time_range(date)[1]
    end

  end
end