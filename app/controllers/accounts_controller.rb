class AccountsController < ApplicationController
  before_filter :authenticate_user!
  
  before_action :load_broker, only: [:new]
  
  before_action :check_authentication, only: [:pass]

  before_action :find_account, only: [:is_login, :login, :refresh_orders, :refresh_positions, :refresh_cash]

  layout 'application'

  def index
    @page_title = "交易账号管理"
    @trading_accounts = TradingAccount.published.sort_by_login.by_user(current_user.id)
    @account_id = params[:account_id].present? ? params[:account_id] : @trading_accounts.first.try(:pretty_id)
    @sub_menu_tab = "accounts"
  end

  def show
    @page_title = "账号详情页面"
    
    @account = TradingAccount.find_with_pretty_id(@current_user.id, params[:id])
  end

  def new
    @page_title = "#{@broker.cname}账号绑定"
    render "/accounts/new/#{@broker.bind_type}"
  end

  def create
    @broker = Broker.find(params[:broker_id])
    @page_title = "#{@broker.cname}账号绑定"
    @trading_account = TradingAccount.bind(@current_user, @broker, account_params)
  end

  def pass
    @page_title = "绑定账号激活页面"

    redirect_to account_overview_index_path(@trading_account.pretty_id) if @trading_account.bind!
  end
  
  def destroy
    TradingAccount.unbind(current_user, params[:id])
    
    redirect_to accounts_path
  end

  def is_login
    datas = {status: @account.logined?}
    datas.merge!(broker_info: @account.broker_info, need_comunication: @account.need_communication_password?) unless datas[:status]
    render json: datas
  end

  def login
    status = @account.login(params[:password], params[:communication_password])
    render json: {status: status}
  end

  def refresh_orders
    status = @account.refresh_cash
    render json: {status: status}
  end

  def refresh_positions
    status = @account.refresh_cash
    render json: {status: status}
  end

  def refresh_cash
    status = @account.refresh_cash
    render json: {status: status}
  end

  def order_details
    @account = TradingAccount.find_by_pretty_id(params[:id]).first
    @order_details = @account.order_details_by(params[:page])
  end

  private
  def load_broker
    @broker = Broker.find_by!(name: params[:broker_id])
  end

  def account_params
    params.require(:trading_account).permit(:broker_no, :password, :safety_info)
  end

  def check_authentication
    @trading_account = TradingAccountEmail.check_confirmation_token(current_user.id, params[:confirmation_token])

    render :pass and return unless @trading_account.errors.empty?
  end

  def find_account
    @account = TradingAccount.find_with_pretty_id(@current_user.id, params[:id])
  end

end
