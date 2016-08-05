# 无用
class AdjustBasketByAccount
  attr_reader :basket, :account

  def initialize(basket_id, account_id)
    @basket = Basket.normal.find(basket_id)
    @account = TradingAccount.find(account_id)
  end

  def call
    ActiveRecord::Base.transaction do
      contest_basket.basket_stocks = new_basket_stocks
      contest_basket.update(modified_at: order.updated_at, parent_id: basket.latest_history_id)
      contest_basket.copy_to_history_version(false)
    end
    create_adjustment
  end

  private

  def original_shares
    @original_shares ||= basket.basket_stocks.map{|bs| [bs.stock_id, bs.real_share] }.to_h
  end

  def original_weights
    @original_weights ||= basket.stock_weights
  end

  def original_cash_weight
    original_weights[Stock::Cash.id]
  end

  def now_stock_shares
    @now_stock_shares ||= Position.account_with(account.id).where("shares <> 0").map{|p| [p.base_stock_id, p.shares.to_i]}.to_h
  end

  def account_total_value
    trading_account.total_property
  end

  def stock_prices
    @stock_prices ||= all_stock_ids.map do |stock_id|
      price = Rs::Stock.find(stock_id).realtime_price
      [stock_id, price]
    end.to_h
  end

  def all_stock_ids
    (original_weights.keys + now_stock_shares.keys).uniq
  end

  def old_weights
    @old_weights ||= cal_weights_by_shares(original_shares)
  end

  def now_stock_weights
    @new_weights ||+ cal_weights_by_shares(now_stock_shares)
  end

  def cal_weights_by_shares(stock_shares)
    weights = stock_shares.map do |stock_id, shares|
      stock_total = stock_prices[stock_id] * shares
      weight = account_total_value.zero? ? 0 : stock_total/account_total_value
      [stock_id, weight]
    end.to_h
    Stock::Cash.id_weights_with(weights)
  end

  def low_acc_weights
    @low_acc_weights ||= BasketIndex::RealtimeWeight.send(:to_low_accurate, new_weights)
  end

  def new_basket_stocks
    basket_stocks = []
    now_stock_weights.select{|sid, _| sid>0 }.each do |stock_id, weight|
      basket_stocks << BasketStock.new(
        stock_id: stock_id, basket_id: basket.id, weight: low_acc_weights[stock_id], 
        adjusted_weight: weight, ori_weight: weight, real_share: now_stock_shares[stock_id]
      )
    end
    basket_stocks
  end

  def create_adjustment
    # 只记录交易股票
    adjustment = BasketAdjustment.create({
      state: BasketAdjustment::STATES[:normal], prev_basket_id: prev_basket_id, 
      next_basket_id: basket.latest_history_id, original_basket_id: basket.id
    })
    adjust_logs = all_stock_ids.map do |stock_id|
      BasketAdjustLog.new(
        basket_adjustment_id: adjustment.id, stock_id: stock_id, 
        weight_from: original_weights[stock_id] || 0, weight_to: now_stock_weights[stock_id], 
        stock_price: stock_prices[stock_id], realtime_weight_from: old_weights[stock_id] || 0
      )
    end
    adjust_logs << BasketAdjustLog.new(
        basket_adjustment_id: adjustment.id, weight_from: original_cash_weight, 
        weight_to: now_stock_weights[Stock::Cash.id]
      )
    BasketAdjustLog.import(adjust_logs, validate: true)
  end
end