class OrderSell < Order
  before_validation :set_instance_id, if: Proc.new {|o| o.new_record?}
  validate :have_enough_stock_shares, on: :create
  
  def buy_order?
    false
  end

  def real_profit
    if external?
      nil
    else
      self.order_details.map{|od| od.profit }.sum.to_f.round(2)
    end
  end

  def valid_trade
    have_enough_stock_shares
  end

  private
  def set_instance_id
    self.instance_id = self.basket_id.present? ? self.basket.original_id : Position::TYPES[:others]
  end

  def have_enough_stock_shares
    positions = self.basket_id.present? ? 
                Position.basket_positions_by(instance_id, user_id, trading_account_id) : 
                Position.stock_positions_by(order_details.first.base_stock_id, user_id, trading_account_id) 
    can_sell_stocks_shares = positions.map{|x| [x.base_stock_id, x.can_selled_shares]}.to_h 
    want_sell_stocks_shares = self.order_details.map{|x| [x.base_stock_id, x.est_shares]}.to_h
    overranging_stocks = want_sell_stocks_shares.select{|stock_id, shares| shares.to_i > can_sell_stocks_shares[stock_id].to_i}
    errors.add(:exceeded_stock_count, '卖出的股票数量超出实际可卖数量，请刷新页面后再次操作！') if overranging_stocks.present?
  end
end
