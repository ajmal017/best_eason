# for 订单管理
class OrderSearch
  FIELDS = :account, :market, :trade_type, :product_type, :status, :query_word

  MARKETS = {:"" => "全部市场", cn: "沪深", hk: "港股", us: "美股"}
  TRADE_TYPES = {:"" => "不限", OrderBuy: "买入", OrderSell: "卖出"}
  PRODUCT_TYPES = {:"" => "全部类别", stock: "股票", basket: "组合"}
  STATUSES = {:"" => "全部状态", completed: "交易完成", partial_completed: "部分完成", cancelled: "交易取消", expired: "交易失效", progressing: "已报"}

  attr_reader :accounts

  def initialize(user, opts = {})
    opts ||= {}
    @user = user
    @opts = opts.symbolize_keys
    process_trading_accounts
  end

  FIELDS.each do |field|
    define_method field do
      @opts[field].to_s
    end

    define_method "#{field}=" do |value|
      @opts[field] = value
    end

    define_method "#{field}_active?" do |value|
      send(field) == value.to_s
    end
  end

  # 排除account
  FIELDS[1..-1].each do |field|
    define_method "#{field}_desc" do
      key = send(field).to_sym
      self.class.const_get(field.to_s.pluralize.upcase)[key]
    end
  end

  def account_desc
    @accounts[account]
  end

  def account_for_menu
    account.blank? ? @trading_accounts.first.pretty_id : account
  end

  def to_params
    @opts
  end

  def processing_orders
    orders.in_progress.search(search_params).result(distinct: true).order("created_at desc")
          .includes(:basket, :order_details => :stock, :trading_account => :broker)
  end

  def history_orders
    orders.search(search_params).result(distinct: true).finished
          .includes(:basket, :order_details => :stock, :trading_account => :broker)
          .paginate(page: page, per_page: 10)
  end

  def show_refresh?
    @trading_account.try(:market_cn?) || (account.blank? && @trading_accounts.count==1 && @trading_accounts.first.try(:market_cn?))
  end

  private
  def process_trading_accounts
    @trading_accounts = TradingAccount.accounts_by(@user.id)
    @trading_account = TradingAccount.find_with_pretty_id(@user.id, account)
    if @trading_account.blank?
      @trading_account = @trading_accounts.first
      @opts[:account] = @trading_account.pretty_id
    end
    accounts_map
  end

  def accounts_map
    @accounts = {}
    @trading_accounts.map do |account|
      @accounts[account.pretty_id] = "#{account.broker_name}<em>#{account.broker_no}</em>"
    end
  end

  def orders
    orders = @user.orders.where(trading_account_id: @trading_accounts.map(&:id))
    orders = orders.in_progress if status_progressing?
    orders
  end

  def search_params
    params = {
      type_eq: trade_type, product_type_eq: product_type, market_eq: market, 
      trading_account_id_eq: decoded_account_id
    }
    params.merge!(sn_or_order_details_stock_symbol_or_order_details_stock_c_name_or_order_details_stock_name_or_basket_title_cont: query_word) if query_word.present?
    params.merge!(status_eq: status) if !status_progressing?
    params
  end

  def status_progressing?
    status == 'progressing'
  end

  def page
    @opts[:page] || 1
  end

  def decoded_account_id
    Caishuo::Utils::Encryption.decode_pretty_id(account).try(:first)
  end
end