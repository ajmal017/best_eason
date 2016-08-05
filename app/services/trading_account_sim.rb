class TradingAccountSim < TradingAccountPassword
  INIT_MONEY = 1000000

  attr_accessor :admin

  before_destroy do
    unless admin
      self.errors.add :broker_no, '模拟账号不能解绑'
      false
    end
  end

  def self.account_by(user_id, market = :cn)
    broker = broker_by(market)
    self.by_user(user_id).where(broker_id: broker.id).binded.first
  end

  def self.opened?(user_id, market = :cn)
    account_by(user_id, market).present?
  end

  def self.open(user_id, market = :cn)
    if opened?(user_id, market)
      return self.new.tap do |a|
        a.errors.add :broker_no, '已经创建了模拟账户'
      end
    end

    exchange = exchange_by(market)
    master_account = Setting.trading_account.sim[market]
    account = RestClient.trading.account.open_account(master_account, user_id, exchange, INIT_MONEY)
    account.open_init(market, INIT_MONEY) if account.id.present?
    account
  end

  def open_init(market, money)
    date = ClosedDay.get_work_day(Date.today-1, market)
    UserDayProperty.create(user_id: user_id, date: date, total: money, total_cash: money, base_currency: base_currency, trading_account_id: id)
    cal_profit_percents(true)
  end

  def bank_transfer(money)
    RestClient.trading.account.bank_transfer(id, money)
  end

  def cancelable?
    false
  end

  def login(password, safety_info = nil)
    true
  end

  def logined?
    true
  end

  def analog?
    true
  end

  def category_name
    "模拟账号"
  end

  # 对比大盘
  def sim_contrast(type="day")
    account_proportion = change_ratio(type)
    market_proportion = BaseStock.market_profit(date_by(type)[1], point_market) rescue 0
    { market_proportion: market_proportion, account_proportion: account_proportion.round(4).to_f }
  end

  # 对比日期，第一个account对比日期，第二个大盘对比日期
  def date_by(type="day")
    start_date = created_at.to_date - 1
    date =
      case type
      when "day"
        cutoff_holding_date
      when "month"
        Date.today.last_month
      when "year"
        Date.today.beginning_of_year
      when "total"
        start_date
      end
    adjusted_date = date < start_date ? start_date : date

    # 修正日期到交易日当天
    return [ClosedDay.get_work_day(adjusted_date, broker.market), ClosedDay.get_work_day(date, broker.market)]
  end

  def change_ratio(type="day")
    profit_and_percent_by(type)[1]/100 rescue 0
  end

  def profit_and_percent_by(type="day")
    prev_property = property_by(date_by(type)[0])
    profit = total_property - prev_property
    percent = profit * 100 / prev_property rescue 0
    return [profit, percent]
  end

  def property_by(date)
    $cache.fetch("cs:account:property:#{id}:#{date.to_s(:db)}", expires_in: 1.days) do
      UserDayProperty.find_by(trading_account_id: id, date: date).total rescue INIT_MONEY
    end
  end

  def cal_profit_percents(force = false)
    ordered = !orders.count.zero?
    return unless ordered || force

    imports = AccountRank::RANK_TYPES.map do |type|
      profit, percent = profit_and_percent_by(type)
      [user_id, broker_id, id, type, total_property, percent, profit, Date.today, ordered]
    end
    ImportProxy.import(
      AccountRank, %w(user_id broker_id trading_account_id rank_type property percent profit date ordered), 
      imports, validate: false, on_duplicate_key_update: [:property, :percent, :profit, :date, :broker_id, :user_id, :ordered]
    )
  end

  # 战胜 % 财说用户
  def ranking_percent(type)
    total_count = AccountRank.ordered.where(broker_id: broker_id, rank_type: type).count || 1
    my_percent = AccountRank.find_by(trading_account_id: id, rank_type: type).try(:percent) || 0
    below_count = AccountRank.ordered.where(broker_id: broker_id, rank_type: type).where('percent < ?', my_percent).count
    (below_count*100/total_count).to_i
  end

  def frozen_cash
    @frozen_cash_account_value ||= account_values.frozen_cash.first
    cash(@frozen_cash_account_value)
  end

  # 未考虑货币转换，模拟账户的account_value现在是对应货币的数字，如果有一账户多货币，删除此方法
  def full_cash
    @full_cash ||= account_values.usable_and_frozen.sum(:value)
  end

  def snapshot_url(type = "day")
    time = Time.now
    params_str = Caishuo::Utils::Encryption::UrlSafe.encode("#{pretty_id}_#{type}_#{time.to_i}")
    "http://#{Setting.mobile_domain}/shares/snapshots/account/#{time.to_date.jd}/#{params_str}.html"
  end

  def analysis_snapshot_url(year = Time.now.year)
    time = Time.now
    params_str = Caishuo::Utils::Encryption::UrlSafe.encode("#{pretty_id}_#{year}_#{time.to_i}")
    "http://#{Setting.mobile_domain}/shares/snapshots/account_analysis/#{time.to_date.jd}/#{params_str}.html"
  end

  private
  def self.exchange_by(market)
    {cn: nil, us: "P"}.with_indifferent_access[market]
  end

  def self.broker_by(market)
    master_account = Setting.trading_account.sim[market]
    Broker.find_by_master_account(master_account)
  end

  def profit_by(date)
    $cache.fetch("cs:account:profit:#{id}:#{date.to_s(:db)}", expires_in: 1.days) do
      UserProfit.find_by(trading_account_id: id, date: date).total_pnl rescue 0
    end
  end

end
