class BasketUpdateStocks
  attr_reader :basket, :params, :weight_changed

  def initialize(basket, basket_params)
    @basket = basket
    @params = basket_params.merge(parent_id: basket.latest_history_id, modified_at: Time.now)
    @weight_changed = stocks_weight_different?
  end

  def call
    return false unless stocks_count_valid?
    return false if weight_changed && (sell_over_limit? || buy_over_limit?)
    update_stocks
  end

  private

  def update_stocks
    ActiveRecord::Base.transaction do
      status = update_stocks_attrs
      basket.copy_to_history_version if status && !basket.draft? && weight_changed
      basket.add_feed(:basket_adjust) if !basket.draft? && weight_changed
      status
    end
  end

  def update_stocks_attrs
    basket.basket_stocks = BasketStock.where(basket_id: basket.id, id: current_stock_ids)
    # 只有草稿状态的才能更新contest
    # self.contest = (contest || basket_params.delete(:contest)) if draft?
    basket.update(adjusted_params)
  end

  def current_stock_ids
    params[:basket_stocks_attributes].map{|k, v| v["id"]}.delete_if(&:blank?)
  end

  def adjusted_params
    params.merge!(parent_id: basket.latest_history_id, modified_at: Time.now)
    params[:basket_stocks_attributes].map do
      |k, v| v.merge!(adjusted_weight: v["weight"], ori_weight: v["weight"])
    end
    params
  end

  def stocks_count_valid?
    !(new_stock_weights.size.zero? || new_stock_weights.size>30)
  end

  def original_weights
    @original_weights ||= basket.stock_weights_without_cash
  end

  def new_stock_weights
    @new_stock_weights ||= params[:basket_stocks_attributes].values.map{|infos| [infos[:stock_id].to_i, infos[:weight].to_d]}.to_h
  end

  def stocks_weight_different?
    return true if original_weights.select{|_, w| w>0 }.keys.sort != new_stock_weights.select{|_, w| w>0 }.keys.sort
    original_weights.map{|stock_id, weight| new_stock_weights[stock_id] != weight}.any?
  end

  # 返回true 代表卖出超出超限
  def sell_over_limit?
    return false unless basket.is_cn? && exchange.trading?
    
    can_change_weights = basket.now_can_sell_weights
    original_weights.map do |stock_id, weight|
      new_weight = new_stock_weights[stock_id] || 0
      change_weight = new_weight - weight
      if change_weight >= 0
        false
      else
        can_change = can_change_weights[stock_id] || 0
        can_change + 0.002 < change_weight.abs
      end
    end.any?
  end

  # 大赛组合股票单个比例不能大于50%（原有50%经过系统调仓大于50的，只要不高于当前比例就行）
  def buy_over_limit?
    return false unless basket.join_contest?

    new_stock_weights.map do |stock_id, weight|
      old_weight = original_weights[stock_id] || 0
      weight_change = weight - old_weight
      weight_change > 0 && weight > 0.5 ? true : false
    end.any?
  end

  def exchange
    basket.exchange_instance
  end
end