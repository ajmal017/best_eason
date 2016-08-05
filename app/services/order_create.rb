class OrderCreate
  attr_reader :user, :account, :trade_type, :order_params, :adjust_stocks_param

  def initialize(user, trade_type, order_params, adjust_stocks_param = {})
    @user = user
    @account = find_account(order_params[:trading_account_id])
    @trade_type = trade_type
    @order_params = order_params
    @adjust_stocks_param = adjust_stocks_param
  end

  def call
    checked_result = check_conditions
    return checked_result if checked_result[:error]

    adjust_params_for_basket_adjust

    order = trade_type.constantize.new(adjusted_params)
    if order.save
      { order_id: order.id }
    else
      $order_fail_logger.error("[#{Time.now}] Msg: #{order.errors.messages.values.join("; ")}")
      {error: true, error_msg: order.errors.messages.values.join("; ")}
    end
  end

  private

  def find_account(trading_account_id)
    TradingAccount.find_with_pretty_id(user.id, trading_account_id)
  end

  def buy_order?
    trade_type == "OrderBuy"
  end

  def broker
    @broker ||= account.broker
  end

  def basket_id
    order_params[:basket_id]
  end

  def adjusted_params
    added_params = {trading_account_id: account.id, user_id: user.id, cash_id: account.cash_id}
    order_params.merge!(added_params)
    adjust_order_details = order_params[:order_details_attributes].select{|k,v| v[:est_shares].to_i > 0 }
    order_params.merge(order_details_attributes: adjust_order_details)
  end

  def check_conditions
    checked_result = check_trading_account
    return checked_result if checked_result[:error]

    check_stocks
  end

  def check_trading_account
    return {error: true, error_msg: "交易账号错误！"} if account.blank?
    return {error: true, recert: true, error_msg: "账号需要重新认证！"} if account.recert?

    if Rails.env.production? && broker.market_cn?
      exchange = Exchange::Base.by_area("cn")
      if exchange.workday? && exchange.market_close? && (Date.today == broker.trading_date)
        return {error: true, error_msg: "A股交易系统正在日切，请稍后下隔夜单！"}
      end
    end

    return {login: false, error: true, error_msg: "请登录券商账号！"} unless account.logined?
    return {error: true, error_msg: "实盘大赛账号只能下限价单！"} if trade_types_error?

    if buy_order?
      return {error: true, error_msg: "您的账号不能购买股票！"} if can_not_buy?
      return {error: true, error_msg: "实盘大赛账号单只股票市值不能大于50%！"} if over_positions_limit?
    else
      return {error: true, error_msg: "您的账号不能卖出股票！"} if can_not_sell?
    end

    {}
  end

  # A股，pt只能挂限价单
  def trade_types_error?
    return false unless pt_account?
    trade_types = order_params[:order_details_attributes].values.map{|x| x[:order_type]}.uniq
    ["0"] != trade_types ? true : false
  end

  def pt_account?
    account.is_a? TradingAccountPT
  end

  def can_not_buy?
    return false unless pt_account?
    buy_order? && account.can_not_buy?
  end

  def can_not_sell?
    return false unless pt_account?
    !buy_order? && account.can_not_sell?
  end

  # pt账户单只股票不能买入多余50%，pt暂时不能购买组合，只按一只计算
  def over_positions_limit?
    return false unless pt_account?
    total = account.total_property
    return false if total.zero?

    stock_id = trade_stocks.keys.first
    current_stock_value = account.stock_market_value_of(stock_id).to_f
    buying_details_value = account.today_buying_value_of(stock_id).to_f
    (current_stock_value + buying_details_value + order_total_money)/total > 0.5
  end

  def check_stocks
    if basket_id.blank?
      stock = BaseStock.where(id: trade_stocks.keys).limit(1).first
      return {error: true, error_msg: "该股票已停牌，暂时无法交易！"} if stock.trading_halt?
    end
    {}
  end

  def adjust_params_for_basket_adjust
    #todo: adjust_stocks 取数据问题，从position中取？
    if adjust_stocks.present?
      operate_method = buy_order? ? "+" : "-"
      stock_count_hash = adjust_stocks.map do |stock_id, count|
        [stock_id.to_i, count.to_i.send(operate_method.to_sym, trade_stocks[stock_id].to_i)]
      end.reject{|id, count| count <= 0}.to_h

      custom_basket = Basket.custom_from(original_basket_id, stock_count_hash, user)
      order_params.merge!(:basket_id => custom_basket.id) if custom_basket
    end
  end

  def buy_order?
    trade_type == "OrderBuy"
  end

  def adjust_stocks
    adjust_stocks_param[:adjust_stocks]
  end

  # todo original 从basket_id查找？
  def original_basket_id
    adjust_stocks_param[:original_basket_id]
  end

  def trade_stocks
    @trade_stocks ||= order_params[:order_details_attributes].values.map{|detail| [detail[:base_stock_id], detail[:est_shares]]}.to_h
  end

  # 暂时只处理pt只下限价单的情况
  def order_total_money
    order_params[:order_details_attributes].values.map{|x| x[:est_shares].to_i * x[:limit_price].to_f}.sum
  end
end
