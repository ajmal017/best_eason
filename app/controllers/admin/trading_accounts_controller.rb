class Admin::TradingAccountsController < Admin::ApplicationController
  before_action :load_account, only: [:audited, :unaudited, :sync_cash, :remote_today_executions, :remote_positions, :remote_today_orders]
  before_action :log_operation, only: [:audited, :unaudited, :sync_cash]

  # 
  def health
    @page_title = "Trading系统状态"
    @drivers = RestClient.trading.health.all
  end

  def index
    @page_title = "交易账号绑定记录"

    @q = TradingAccount.includes(:broker).order(id: :desc).search(params[:q])
    @accounts = @q.result.paginate(page: params[:page] || 1, per_page: params[:per_page] || 20).to_a
  end

  def position
    @page_title = "持仓明细"
    @q = Position.includes(:base_stock, :basket).where(trading_account_id: params[:id]).search(params[:q])
    @positions = @q.result.paginate(page: params[:page] || 1, per_page: params[:per_page] || 20).to_a
  end

  def remote_positions
    @page_title = "远程当日持仓"
    @positions = RestClient.trading.position.remote(@account.id) || []
  end

  def remote_today_executions
    @page_title = "远程当日持仓"
    @executions = RestClient.trading.execution.remote(@account.id) || []
  end

  def remote_today_orders
    @page_title = "当日委托"
    @orders = RestClient.trading.order.remote(@account.id) || []
  end

  # 审核通过
  def audited
    @account.send_active_email if @account.update(email: params[:email], status: TradingAccount::STATUS[:audited], audited_date: Date.today)
  end

  # 审核不通过
  def unaudited
    @account.unaudited! if @account.auditing? || @account.audited?
  end

  # 同步资金
  def sync_cash
    #user_binding = @user_broker.user_binding
    #user_binding.request_portfolio && user_binding.request_account_value if user_binding
  end

  def tries
    @page_title = "交易账号绑定错误记录"
    keys = $redis.keys 'accounts:auth_fail*'
    if keys.present?
      Broker.find(keys.map{|e| e.split(':')[2]})
      User.find(keys.map{|e| e.split(':')[3]})
      @kvs = keys.zip($redis.mget(*keys))
    else
      @kvs = []
    end
  end

  def destroy
    $redis.del(params[:id])
    redirect_to action: :tries
  end

  def execution_history
    @page_title = "远程历史成交"
    @data = RestClient.trading.execution.history(params[:id], params[:start_date], params[:end_date], params[:position_str])
  end

  def order_history
    @page_title = "远程历史委托"
    @data = RestClient.trading.order.history(params[:id], params[:start_date], params[:end_date], params[:position_str])
  end

  def cash_history
    @page_title = "远程历史资金流水"
    @data = RestClient.trading.cash.history(params[:id], params[:start_date], params[:end_date], params[:position_str])
  end

  private
  def log_operation
    notice = "交易账号绑定: " + case params[:action]
    when "sync_cash"
      "同步资金"
    when "unaudited"
      "审核不通过"
    when "audited"
      "审核通过"
    end
    AdminLog.create(resource: {user_broker_id: params[:id]}.to_json, content: notice, log_type: "Trading", request_ip: request.ip, staffer_id: current_admin_staffer.id)
    flash[:notice] = notice
  end

  def load_account
    @account = TradingAccount.find(params[:id])
  end
end
