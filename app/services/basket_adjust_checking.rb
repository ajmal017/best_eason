# 每天开市时检测basket 盘后所做的adjust 并处理
class BasketAdjustChecking
  attr_reader :basket, :market, :date, :last_workday, :today_start_time, :today_end_time, 
              :last_day_start_time, :last_day_end_time, :last_history_basket

  def initialize(basket_id)
    @basket = Basket.find(basket_id)
    @market = basket.market
    @date = Exchange::Base.by_area(market).today
    @last_workday = ClosedDay.get_work_day(date-1, market)
    @today_start_time, @today_end_time = Exchange::Base.by_area(market).trade_time_range(date)
    @last_day_start_time, @last_day_end_time = Exchange::Base.by_area(market).trade_time_range(last_workday)
    @last_history_basket = history_baskets.last
  end

  def self.execute(basket_id)
    self.new(basket_id).call
  end

  def call
    $basket_index_logger.info "#{basket.id} #{Time.now} opening check"
    return unless is_opening?
    $basket_index_logger.info "#{basket.id} doing"
    readjust_stocks_first_day_created if is_first_day_created?

    return "not match conditions" unless can_processing?
    return "processed" if processed?

    if is_valid?
      set_last_history_basket
    else
      reback_basket_version
    end
  end

  private

  def is_opening?
    ClosedDay.is_workday?(date, market) && 
    Time.now >= today_start_time && 
    last_history_basket.present?
  end

  def can_processing?
    first_history_basket.present? && first_history_basket.parent_id.present? && 
    last_workday_weights.present? && prev_day_snapshots.present?
  end

  def processed?
    history_ids = Basket.normal_history.where(original_id: basket.original_id)
                    .where("created_at > ? and created_at < ?", today_start_time, today_end_time)
    BasketAdjustment.opening_adjust.where(next_basket_id: history_ids).limit(1).present?
  end

  # 非交易时段第一个
  def first_history_basket
    @first_history_basket ||= history_baskets.first
  end

  def history_baskets
    @history_baskets ||= Basket.normal_history.where(original_id: basket.original_id)
          .where("created_at >= ? and created_at <= ?", last_day_end_time, today_start_time)
          .order(:id)
  end

  def is_valid?
    stock_changed_weights = changed_weights
    stocks = BaseStock.where(id: stock_changed_weights.keys)
    stocks.map do |s|
      weight = stock_changed_weights[s.id]
      (s.trading_normal? && (weight < 0 ? !s.open_down_limit? : !s.open_up_limit?)) || s.trading_delist?
    end.all?
  end

  def changed_weights
    snapshots = prev_day_snapshots.map{|x| [x.stock_id, x.weight]}.to_h
    latest_weights = last_history_basket.basket_stocks.map{|x| [x.stock_id, x.ori_weight]}.to_h
    stock_ids = (snapshots.keys + latest_weights.keys).uniq
    stock_ids.map do |stock_id|
      prev_weight = snapshots[stock_id] || 0
      next_weight = latest_weights[stock_id] || 0
      change = next_weight - prev_weight
      [stock_id, change]
    end.reject{|x| x[1].zero?}.to_h
  end

  def set_last_history_basket
    basket_adjustment = get_basket_adjustment
    recreate_adjust_logs(basket_adjustment)
    hide_pending_adjustments
    last_history_basket.update(created_at: today_start_time + 60.seconds)
  end

  def get_basket_adjustment
    BasketAdjustment.find_or_create_by({
      prev_basket_id: first_history_basket.parent_id, 
      next_basket_id: last_history_basket.id, 
      original_basket_id: basket.original_id,
      state: BasketAdjustment::STATES[:opening_adjust]
    })
  end

  def recreate_adjust_logs(basket_adjustment)
    prev_stock_infos = prev_basket_stock_infos
    stock_ids = (prev_stock_infos.keys + next_basket_stock_weights.keys).uniq
    basket_adjustment.destroy_logs

    logs = BaseStock.where(id: stock_ids).map do |stock|
      stock_info = {stock_price: stock.open, change_percent: stock.open_change_ratio, weight: 0, realtime_weight: 0}.merge(prev_stock_infos[stock.id] || {})
      BasketAdjustLog.generate(basket_adjustment, stock, stock_info, next_basket_stock_weights[stock.id])
    end
    logs << BasketAdjustLog.generate(basket_adjustment, nil, prev_stock_infos[Stock::Cash.id], next_basket_stock_weights[Stock::Cash.id])
    BasketAdjustLog.import(logs, validate: true)
  end

  def next_basket_stock_weights
    @next_basket_stock_weights ||= last_history_basket.stock_ori_weights
  end

  def hide_pending_adjustments
    change_pending_adjustments(BasketAdjustment::STATES[:hide])
  end

  def cancel_pending_adjustments
    change_pending_adjustments(BasketAdjustment::STATES[:cancel])
  end

  def change_pending_adjustments(state)
    basket_ids = history_baskets.map(&:id)
    BasketAdjustment.pending.where(next_basket_id: basket_ids).update_all(state: state)
  end

  def prev_basket_stock_infos
    return {} if last_workday_weights.blank?
    
    snapshot_weights = prev_day_snapshots.map{|x| [x.stock_id, x.weight]}.to_h
    stock_rets = BasketIndex::StockReturn.realtime_open_rets(last_workday_weights.keys)
    realtime_weights = BasketIndex::RealtimeWeight.adjust_by(last_workday_weights, stock_rets)
    infos = last_workday_weights.keys.map do |stock_id|
      weight = snapshot_weights[stock_id] || 0
      realtime_weight = realtime_weights[stock_id] || 0
      [stock_id, {weight: weight, realtime_weight: realtime_weight}]
    end.to_h
    infos.merge(prev_cash_infos(infos))
  end

  def prev_cash_infos(prev_stock_infos)
    cash_weight = 1 - (prev_stock_infos.values.map{|h| h[:weight]||0}.reduce(:+) || 0)
    {Stock::Cash.id => {weight: cash_weight, stock_price: 1}}
  end

  def last_workday_weights
    @last_workday_weights ||= BasketWeightLog.stock_adjusted_weights(basket.id, last_workday)
  end

  def prev_day_snapshots
    @prev_day_snapshots = BasketStockSnapshot.where(basket_id: first_history_basket.parent_id, next_basket_id: first_history_basket.id)
        .select(:basket_id, :stock_id, :weight, :notes, :adjusted_weight, :ori_weight)
  end

  def reback_basket_version
    return if has_rebacked? || prev_day_snapshots.blank?

    basket_stocks = prev_day_snapshots.map{|x| BasketStock.new(x.attributes.merge(ori_weight: x.adjusted_weight))}
    basket.basket_stocks = basket_stocks
    basket.copy_to_history_version(false)

    cancel_pending_adjustments
    recalculate_basket_index
  end

  def recalculate_basket_index
    Resque.enqueue(BasketIndexQueue, basket.id, last_workday.to_s(:db))
  end

  def has_rebacked?
    basket.latest_history_id != last_history_basket.id
  end

  # ------  交易结束后 创建组合，并调仓  ---------

  def is_first_day_created?
    basket.start_on > last_day_end_time && basket.start_on < today_start_time
  end

  def readjust_stocks_first_day_created
    return if processed?

    readjust_stock_weights_at_start_date_opening

    hide_pending_adjustments
    basket_adjustment = get_basket_adjustment
    recreate_adjust_logs(basket_adjustment)
    last_history_basket.update(created_at: today_start_time + 60.seconds)
  end

  def readjust_stock_weights_at_start_date_opening
    last_history_basket_stocks.map do |bs|
      weight = bs.stock.trading_normal? && !bs.stock.open_up_limit? ? bs.weight : 0
      if !bs.stock.trading_normal? || bs.stock.open_up_limit?
        bs.update(weight: 0, ori_weight: 0)
        update_original_basket_stock(bs.stock_id, {weight: 0, ori_weight: 0})
      end
    end
  end

  def last_history_basket_stocks
    @last_history_basket_stocks ||= last_history_basket.basket_stocks.includes(:stock)
  end

  def original_basket_stocks
    @original_basket_stocks ||= basket.basket_stocks.includes(:stock)
  end

  def update_original_basket_stock(stock_id, attrs)
    basket_stock = original_basket_stocks.select{|bs| bs.stock_id == stock_id}.first
    basket_stock.update(attrs) if basket_stock
  end
end