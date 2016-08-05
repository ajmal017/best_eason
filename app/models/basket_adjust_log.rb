class BasketAdjustLog < ActiveRecord::Base
  ACTIONS = {new: 1, del: 2, add: 3, reduce: 4, system: 5}
  # 备注 5 => "系统调仓"
  STOCK_ACTION_NAMES = {1 => "建仓", 2 => "平仓", 3 => "加仓", 4 => "减仓", 5 => "维持", nil => "维持"}
  CASH_ACTION_NAMES = {1 => "增加", 2 => "减少", 3 => "增加", 4 => "减少", 5 => "维持", nil => "维持"}
  STOCK_ACTION_COLORS = {1 => "#007aff", 2 => "#ff4546", 3 => "#007aff", 4 => "#2fb959", 5 => "#007aff", nil => "#333333"}
  CASH_ACTION_COLORS = {1 => "#007aff", 2 => "#2fb959", 3 => "#007aff", 4 => "#2fb959", 5 => "#007aff", nil => "维持"}
  ICON_CLASSES = {1 => "iconOne", 2 => "iconTwo", 3 => "iconThree", 4 => "iconFour"}

  validates :basket_adjustment_id, :action, :weight_from, :weight_to, presence: true
  # 现金 stock_id 为空
  scope :except_cash, -> { where("stock_id is not null") }
  # validates :stock_id, uniqueness: {scope: :basket_adjustment_id}
  # 减少的
  scope :reduced, -> { where(action: [ACTIONS[:del], ACTIONS[:reduce]]) }
  scope :added, -> { where(action: [ACTIONS[:new], ACTIONS[:add]]) }
  scope :changed, -> { where.not(action: ACTIONS[:system]) }

  belongs_to :basket_adjustment
  belongs_to :stock, class_name: 'BaseStock', foreign_key: :stock_id

  after_initialize :set_action
  before_validation :set_action

  def self.generate(basket_adjustment, stock, prev_snapshot, new_weight)
    log_attrs = {basket_adjustment_id: basket_adjustment.id, stock_id: stock.try(:id), stock_state: stock.try(:market_state)}
    weight_from = prev_snapshot.present? ? prev_snapshot[:weight].to_f : 0
    realtime_weight_from = prev_snapshot.present? ? prev_snapshot[:realtime_weight].to_f : 0
    weight_to = new_weight.to_f
    stock_price = prev_snapshot.present? ? prev_snapshot[:stock_price] : stock.try(:realtime_price)
    self.new(log_attrs.merge(weight_from: weight_from, weight_to: weight_to, stock_price: stock_price, realtime_weight_from: realtime_weight_from))
  end

  def self.stock_action_desc(action)
    STOCK_ACTION_NAMES[action]
  end

  def self.cash_action_desc(action)
    CASH_ACTION_NAMES[action]
  end

  def self.stock_action_color(action)
    STOCK_ACTION_COLORS[action]
  end

  def self.cash_action_color(action)
    CASH_ACTION_COLORS[action]
  end

  def action_desc
    self.stock_id ? self.class.stock_action_desc(self.action) : self.class.cash_action_desc(self.action)
  end

  def action_color
    self.stock_id ? self.class.stock_action_color(self.action) : self.class.cash_action_color(self.action)
  end

  def action_icon
    ICON_CLASSES[self.action]
  end

  def weight_from_percent
    weight_from.round(3) * 100
  end

  def weight_to_percent
    weight_to.round(3) * 100
  end

  def weight_change
    weight_to - weight_from
  end

  def realtime_weight_change
    weight_to - realtime_weight_from
  end

  # 组合指数计算
  def pnl(current_price)
    return 0 if stock_price.zero? || stock_price.blank? || current_trading_halt?
    
    ret = (current_price - stock_price)/stock_price rescue 0
    realtime_weight_change * ret
  end

  def ret_by_price(price)
    return 0 if stock_price.blank? || stock_price.zero? || price.blank? || price.zero?
    (price - stock_price)/stock_price rescue 0
  end

  # stock停牌时，不计算trading
  def current_trading_halt?
    3 == stock_state
  end

  def self.contest_adjusted_stocks(type, start_time, end_time, contest, basket_ids = nil)
    actions = type == "add" ? [1, 3] : [2, 4]
    logs = joins(basket_adjustment: [:original_basket])
        .select("basket_adjust_logs.stock_id, count(basket_adjust_logs.stock_id) as total, weight_from, weight_to")
        .where(
          baskets: {market: "cn", contest: contest},
          action: actions
        ).where("basket_adjust_logs.stock_id is not null")
        .where("basket_adjustments.created_at >= ? and basket_adjustments.created_at <= ?", start_time, end_time)
        .group("basket_adjust_logs.stock_id").order("count(basket_adjust_logs.stock_id) desc")
    logs = logs.where("baskets.id in (?)", basket_ids) if basket_ids.present?
    logs
  end
  
  def stock_name
    stock.try(:com_name) || "现金"
  end
  
  def datas_for_feed
    {stock_name: stock_name, action_name: action_desc, from: weight_from_percent.to_f, to: weight_to_percent.to_f, stock_id: stock_id}
  end

  private
  def set_action
    self.action = get_action
  end

  def get_action
    return ACTIONS[:system] if weight_from == weight_to && realtime_weight_from.present?
    return nil if weight_from == weight_to
    return ACTIONS[:new] if weight_from.zero? && weight_to>0
    return ACTIONS[:del] if weight_from>0 && weight_to.zero?
    return ACTIONS[:add] if weight_from < weight_to
    return ACTIONS[:reduce] if weight_from > weight_to
  end
end
