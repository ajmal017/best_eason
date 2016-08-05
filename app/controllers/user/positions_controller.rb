class User::PositionsController < User::BaseController
  before_action :set_menu
  before_action :check_trading_accounts, only: [:index, :profits]

  def index
    @trading_account = @trading_accounts.select{|t| t.pretty_id==params[:account_id] }.first || @trading_accounts.first
    @stocks_infos, @total_stocks = @trading_account.stocks_infos_by_page(1)
    @baskets_infos = @trading_account.baskets_infos
    @unllocate_positions = @trading_account.unllocate_positions

    @cash_unit = @trading_account.cash_unit
    @total_cash = @trading_account.total_cash
  end

  # 批量获取账户的净值，盈亏，累计盈亏
  def profits
    profits = @trading_accounts.map(&:profits)
    render json: profits
  end

  private
  def set_menu
    @top_menu_tab = "positions"
    @sub_menu_tab = 'position'
    @page_title = "持仓明细"
  end

  def check_trading_accounts
    @trading_accounts = TradingAccount.published.sort_by_login.binded.by_user(current_user.id).includes(:broker)
    redirect_to accounts_path and return if @trading_accounts.blank?
  end
end
