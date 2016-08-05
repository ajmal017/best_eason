class OrderBuy < Order
  before_validation :set_instance_id, if: Proc.new {|o| o.new_record?}
  after_create :set_order_stock_shares_log, if: Proc.new {|o| o.basket_mount.present?}
  before_save :set_buyer_follow_basket, if: Proc.new {|o| o.basket_id.present? && o.status_changed? && o.confirmed?}
  validate :check_user_cash, on: :create
  
  def real_basket_mount
    self.basket_mount.present? ? self.basket_mount : 1
  end

  def buy_order?
    true
  end

  def self.has_executing_order?(user_id, instance_id)
    OrderBuy.where(instance_id: instance_id.to_s, user_id: user_id).confirmed.present?
  end

  def real_profit
    nil
  end

  def valid_trade
    stocks_shares_is_right
    check_user_cash
  end

  private

  def set_instance_id
    self.instance_id = self.basket_id.present? ? self.basket.original_id : Position::TYPES[:others]
  end
  
  def set_order_stock_shares_log
    order_infos_hash = {instance_id: self.instance_id, order_id: self.id, created_at: Time.now, updated_at: Time.now}
    logs_hash_arr = self.order_details.map{|od| {shares: (od.est_shares/self.real_basket_mount).to_i, base_stock_id: od.base_stock_id}.merge(order_infos_hash)}
    # OrderStockShare.create(logs_hash_arr)
    order_stock_shares = logs_hash_arr.map{|attrs| OrderStockShare.new(attrs)}
    ImportProxy.import(OrderStockShare, order_stock_shares, :validate => false)
  end

  def set_buyer_follow_basket
    self.basket.follow_by_user(self.user_id) if self.basket_id.present? && self.status_changed? && self.confirmed?
  end

  def check_user_cash
    if market_cn?
      errors.add(:no_enough_cash, "现金不足！") if est_cost > trading_account.usable_cash
    else
      errors.add(:no_enough_cash, "现金不足！") if self.est_cost_of_usd > trading_account.usable_cash_of_usd
    end
  end
end
