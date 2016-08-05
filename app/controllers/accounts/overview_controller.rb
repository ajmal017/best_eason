class Accounts::OverviewController < Accounts::BaseController
  
  before_action :load_trading_account

  def index
    @page_title = "投资概览"
    
    @today_profit, @today_profit_percent = PositionArchive.today_profit(@trading_account)

    @total_profit = Position.total_profit_and_loss(@trading_account)[0]

    # 货币单位
    @current_cash_unit = @trading_account.cash_unit
    # 证券市值
    @market_value = @trading_account.market_value
    # 账户总金额
    @total_property = @trading_account.full_cash + @market_value
    # 持仓比例
    @position_percent = @market_value.zero? ? 0 : @market_value.fdiv(@total_property) * 100
    
    # 投资胜率
    @profit_percent, @average_percent = Investment.winning_ratio(@trading_account)
    # 投资行业分布比例
    @invest_sector_rates = Investment.sector_ratio(@trading_account)
    # 波动
    @profit_fluctuation = Investment.profit_fluctuation(@trading_account)

    @popular_baskets = Basket.order(one_month_return: :desc).includes(:author).limit(2)

    @popular_stocks = Investment.popular_position_stocks(@trading_account)

    @accounts = TradingAccount.where(user_id: current_user.id).active.published.sort_by_login.includes(:broker)

    gon.account_id = @trading_account.try(:pretty_id)
    @sub_menu_tab = 'investment'
    @top_menu_tab = "positions"
  end

  def positions
    @baskets_infos = Position.buyed_baskets_infos(current_user.id, @trading_account)
    @stocks_infos = Position.buyed_stocks_infos(current_user.id, @trading_account)

    @profit, @profit_percent = PositionArchive.today_profit(@trading_account)

    @total_profit = PositionArchive.total_profit(@trading_account)

    @changes = { 
      profit: @profit,
      total_property: @trading_account.full_cash + @trading_account.market_value, 
      total_cash: @trading_account.full_cash,
      profit_percent: @profit_percent, 
      total_profit: @total_profit, 
      total_profit_percent: @total_profit_percent,
      currency_unit: @trading_account.cash_unit, 
      currency: @trading_account.base_currency
    }

    if @trading_account.is_a?(TradingAccountPassword)
      @changes.merge!({
        usable_cash: @trading_account.usable_cash,
        frozen_cash: @trading_account.frozen_cash
      })
    end
  end

  def orders
    @orders = Order.filled.where(trading_account_id: @trading_account.id).order(id: :desc).includes(:basket).includes(:order_details => :stock).limit(10)
  end
  
  def news
    stock_ids = Position.where(user_id: current_user.id).map(&:base_stock_id).uniq[0..39]

    @news = RestClient.api.stock.news.batch(stock_ids.join(','), true, params[:page] || 1, 20)
  end

  private

  def load_trading_account
    if params[:account_id].blank?
      @trading_account = current_user.trading_accounts.active.published.sort_by_login.first
      
      redirect_to accounts_path if @trading_account.blank?
    else
      super
    end
  end
  
  def broker_name
    @broker_name ||=  @trading_account.try(:broker).try(:name)
  end
end
