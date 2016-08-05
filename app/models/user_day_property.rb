class UserDayProperty < ActiveRecord::Base
  validates :user_id, :date, presence: true
  validates_uniqueness_of :date, scope: [:user_id, :trading_account_id]

  scope :by_user, -> (user_id) { where(user_id: user_id) }
  scope :account_with, ->(account_id) { where(trading_account_id: account_id) }
  scope :available, -> { where("trading_account_id is not null and base_currency is not null") }

  def rate_name(user_currency)
    base_currency.to_s.downcase + '_to_' + user_currency.to_s.downcase
  end

  def total
    read_attribute(:total).to_f
  end

  def usd_total
    total * Currency.transform(base_currency, 'USD')
  end

  def chart_timestamps
    (date.to_time + 8.hours).to_i * 1000
  end

  def self.net_return_percent(account, begin_date)
    properties = net_value_datas_by(account, begin_date)
    if properties.present?
      _, base = properties.first
      properties.map do |ts, total|
        {date: ts, value:(total/base-1.0)}
      end
    else
      []
    end
  end

  # TODO market
  def self.net_value_datas_by(account, begin_date)
    currency = Currency::Base.new(account.base_currency)
    market = account.is_a?(TradingAccountPassword) ? :cn : :us
    properties = account_with(account.id).order(date: :asc).where("date >= ?", (begin_date || '2009-01-01')).to_a
    flag = false
    properties.map do |p|
      next unless ClosedDay.is_workday?(p.date, market)
      flag = (p.total != 0 || flag)
      next unless flag
      [p.chart_timestamps, p.total * currency.rate(p.base_currency)]
    end.compact
  end

  def self.today
    Date.today.to_s("yyyy-mm-dd")
  end

  def self.datas_by(account, begin_date, end_date=today)
    currency = Currency::Base.new(account.base_currency)
    datas = account_with(account.id).order(date: :asc).where("date >= ? and date <= ?", (begin_date || '2009-01-01'), end_date||today).map do |p|
      next if p.date.saturday? || p.date.sunday?
      [p.chart_timestamps, (p.total * currency.rate(p.base_currency)).to_f.round(2)]
    end.compact

    # 添加当天数据
    if account.market_cn? && ClosedDay.is_workday?(Date.today, :cn)
      today_chart_timestamp = Date.today.to_time(:utc).to_i * 1000 
      if datas.blank? || (datas.present? && datas.last.first < today_chart_timestamp)
        datas << [today_chart_timestamp, account.total_property.to_f.round(2)]
      end
    end
    
    datas
  rescue Exception => e
    datas
  end

  # account好友30天回报百分比
  def self.account_friends_30days_return(account, begin_date = 31.days.ago.to_date)
    user_ids = account.user.friends.map(&:followable_id).push(account.user_id)

    results = {}
    by_user(user_ids).where("date >= ?", begin_date).available.group_by(&:user_id).map do |user_id, properties|
      if properties.any?{|p| p.trading_account_id == account.id}
        max_property = return_precent_block.call(properties.select{|p| p.trading_account_id == account.id})
      else
        max_property = properties.group_by(&:trading_account_id).map{|account_id, ps| return_precent_block.call(ps)}.max
      end
      results.merge({user_id => max_property})
    end

    user_ids.map do |user_id|
      [results.key?(user_id) ? results[user_id] : -10000, user_id]
    end    
  end

  def self.return_precent_block
    Proc.new do |properties|
      base, current = properties.minmax_by{|p|p.date}.map{|p|p.total * Currency.transform(p.base_currency, 'USD')}
      base.zero? ? 0 : current.fdiv(base) - 1.0
    end
  end

  # 美股港股计算账户净值 
  def self.sync(account, date, foreign=true)
    return if account.is_a?(TradingAccountPassword) && foreign

    currency = Currency::Base.new(account.base_currency)

    market_value = PositionArchive.where(trading_account_id: account.id, archive_date: date).inject(0) do |sum, pa|
      sum += pa.shares * pa.close_price * currency.rate(pa.currency)
    end

    total_cash = AccountValueArchive.where(trading_account_id: account.id, archive_date: date).where(key: AccountValue::TYPES[:total_cash_balance]).where(currency: AccountValue::UNITS.values_at(:base, :cny)).to_a.inject(0) do |sum, av|
      sum + av.total_cash(account.base_currency)
    end

    property = find_or_initialize_by(trading_account_id: account.id, date: date)
    
    if account.is_a?(TradingAccountPT)
      total_property = AccountValueArchive.find_by(trading_account_id: account.id, archive_date: date, key: 'AssetBalance').try(:value).to_f
      property.update(total: total_property, total_cash: total_cash, base_currency: account.base_currency, user_id: account.user_id)
    else
      property.update(total: market_value + total_cash, total_cash: total_cash, base_currency: account.base_currency, user_id: account.user_id)
    end
    
    $investment_logger.info "账户净值===#{account.id}, date: #{date}, market_value: #{market_value}, total_cash: #{total_cash}"
  rescue Exception => e
    Caishuo::Utils::Email.deliver(Setting.investment_notifiers.email, Rails.env, "账户净值归档出错:#{date} #{account.id} #{e.message}")
  end

  # A股账户净值计算
  def self.cn_sync(account)
    property = find_or_initialize_by(trading_account_id: account.id, date: Date.today)
    
    attrs = {
      total: account.total_property, 
      total_cash: account.total_cash, 
      base_currency: account.base_currency, 
      user_id: account.user_id
    }
    property.update(attrs)
  rescue Exception => e
    $investment_logger.info "A股账户净值===#{account.id}, date: #{Date.today.to_s(:db)}, #{e.message}"
  end

  # 美股港股券商净值计算
  def self.ib_sync(account, date = Date.yesterday)
    raise "date must greater than yesterday!!!" if date < Date.yesterday

    find_or_initialize_by(trading_account_id: account.id, date: date).update(
      total: account.total_property,
      total_cash: account.total_cash,
      base_currency: account.base_currency,
      user_id: account.user_id
    )
  rescue Exception => e
    $investment_logger.info "美股港股账户净值===#{account.id}, date: #{Date.today.to_s(:db)}, #{e.message}"
  end

  def self.profit_between(account_id, begin_date, end_date)
    begin_property = account_with(account_id).where("date >= ?", begin_date).first.try(:total) || 0
    end_property = account_with(account_id).where("date <= ?", end_date).last.try(:total) || 0
    end_property - begin_property
  end
end
