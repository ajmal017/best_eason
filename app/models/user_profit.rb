# 每日利润
class UserProfit < ActiveRecord::Base
  belongs_to :user

  validates_uniqueness_of :trading_account_id, scope: [:date]

  scope :by_user, -> (user_id) { where(user_id: user_id) }
  scope :account_with, ->(account_id) { where(trading_account_id: account_id) }
  scope :date_gte, -> (date, end_date = today) { where("date >= ? and date <= ?", date, end_date || today) }

  def total_pnl
    read_attribute(:total_pnl).to_f
  end

  def chart_timestamps
    (date.to_time + 8.hours).to_i * 1000
  end

  # 投资概览/收益表现图数据
  def self.datas_by(account, begin_date, end_date=today)
    currency = Currency::Base.new(account.base_currency)
    datas = account_with(account.id).date_gte(begin_date, end_date).order(:id).map do |up|
      next if up.date.saturday? || up.date.sunday?
      [up.chart_timestamps, (up.total_pnl * currency.rate('USD').to_f).to_f.round(2)]
    end.compact

    # 添加当天数据
    if datas.present? && account.market_cn? && ClosedDay.is_workday?(Date.today, :cn)
      today_chart_timestamp = Date.today.to_time(:utc).to_i * 1000
      if datas.last.first < today_chart_timestamp
        datas << [today_chart_timestamp, PositionArchive.total_profit(account).to_f.round(2)]
      end
    end

    datas
  rescue Exception => e
    datas
  end

  def self.today
    Date.today.to_s("yyyy-mm-dd")
  end

  # 每日同步用户收益(要考虑非交易日的情况)
  def self.sync(account, date)
    today_pnl = holding_pnl(account, date) + trading_pnl(account, date) + exec_trading_pnl(account, date) - commission_pnl(account, date)

    usd_today_pnl = today_pnl * Currency.transform(account.base_currency, 'USD')
    user_profit = find_or_initialize_by(trading_account_id: account.id, date: date)
    previous_record = previous_profit(account.id, date)
    usd_totol_pnl = (previous_record.try(:total_pnl) || 0.0) + usd_today_pnl
    ori_total_pnl = (previous_record.try(:ori_total_pnl) || 0.0) + today_pnl
    user_profit.update(today_pnl: usd_today_pnl, total_pnl: usd_totol_pnl, user_id: account.user_id, ori_today_pnl: today_pnl, ori_total_pnl: ori_total_pnl)

    $investment_logger.info("用户收益===trading_account_id: #{account.id}, date: #{date}, today_pnl: #{today_pnl}")
  rescue Exception => e
    Caishuo::Utils::Email.deliver(Setting.notifiers.email.last, nil, "收益表现同步出错#{Rails.env}", e.message)

    $investment_logger.error(e.inspect)
  end

  def self.previous_pnl(account_id, date)
    where("trading_account_id = ? and date < ?", account_id, date).order(date: :desc).first.try(:total_pnl) || 0.0
  end

  def self.previous_profit(account_id, date)
    where("trading_account_id = ? and date < ?", account_id, date).order(date: :desc).first
  end

  def self.holding_pnl(account, date)
    currency = Currency::Base.new(account.base_currency)

    pnl = 0
    PositionArchive.select("base_stock_id, market, shares, adjusted_shares").where(trading_account_id: account.id, archive_date: date - 1).group_by(&:historical_klass).map do |historical_klass, ps|
      changes = historical_klass.where(base_stock_id: ps.map(&:base_stock_id), date: date).inject({}) do |ret, quote|
        ret.merge!(quote.base_stock_id => quote.change_from_last_close * currency.rate(quote.currency))
      end
      pnl += ps.inject(0) { |sum, p| sum + p.adjusted_shares * changes[p.base_stock_id].to_f }
    end

    pnl
  end

  # trading price取股票未复权价格
  def self.trading_pnl(account, date)
    currency = Currency::Base.new(account.base_currency)

    profit = 0
    OrderDetail.account_with(account.id).where(*PositionArchive.trade_time_scope(trade_time_range(account, date))).profited.group_by(&:historical_price_class).map do |historical_klass, ods|
      od_values = ods.map do |od|
        [od.base_stock_id, [od.real_shares.to_i, od.real_cost.to_f, od.trading_flag * currency.rate(od.currency)]]
      end

      prices = historical_klass.where(base_stock_id: od_values.map(&:first).uniq, date: date).map { |quote| [quote.base_stock_id, quote.last] }.to_h

      profit += od_values.map do |base_stock_id, infos|
        next unless prices.key?(base_stock_id)

        (prices[base_stock_id] * infos[0] - infos[1]) * infos[2]
      end.compact.sum.to_f
    end

    profit
  end

  # 手续费
  def self.commission_pnl(account, date)
    return 0 unless account.is_a?(TradingAccountSim)

    date = Date.parse(date) if date.is_a?(String)
    OrderDetail.where(trading_account_id: account.id, trade_time: [date..date + 1 - 1.second]).profited.sum("commission")
  end

  # 其他地方产生的交易
  def self.exec_trading_pnl(account, date)
    return 0.0 if account.is_a?(TradingAccountPassword)

    currency = Currency::Base.new(account.base_currency)

    execs = account.exec_class.by_user(account.user_id).where(*PositionArchive.exec_time_scope(exec_trading_range(account, date))).profited.map do |ex|
      [ex.stock_id, [ex.avg_price, ex.shares.to_i * ex.trading_flag * currency.rate(ex.currency)]]
    end

    prices = {}
    BaseStock.select("id, type").where(id: execs.map(&:first)).group_by(&:historical_klass).each do |historical_klass, bs|
      prices.merge!(historical_klass.where(base_stock_id: bs.map(&:id).uniq, date: date).map {|quote| [quote.base_stock_id, quote.last]}.to_h)
    end

    execs.map do |base_stock_id, ex_values|
      next unless prices.key?(base_stock_id)
      (prices[base_stock_id] - ex_values[0]) * ex_values[1]
    end.sum.to_f
  end

  # TODO 此处需要添加a股的交易时间
  def self.exec_trading_range(account, date)
    date = date.to_s(:db) if date.is_a?(Date)

    if account.is_a?(TradingAccountEmail)
      [
        { start: Exchange::Hk.instance.exec_trading_start(date), end: Exchange::Hk.instance.exec_trading_end(date) },
        { start: Exchange::Us.instance.exec_trading_start(date), end: Exchange::Us.instance.exec_trading_end(date) }
      ]
    else
      [
        { start: "#{date} 00:00:00".to_time,   end: "#{date} 23:59:59".to_time }
      ]
    end
  end

  # TODO 此处需要添加a股的交易时间
  def self.trade_time_range(account, date)
    date = date.to_s(:db) if date.is_a?(Date)

    if account.is_a?(TradingAccountEmail)
      [
        { start: "#{date} 00:00:00".to_time,   end: "#{date} 23:59:59".to_time,   market: 'hk' },
        { start: "#{date} 00:00:00".to_estime, end: "#{date} 23:59:59".to_estime, market: 'us' }
      ]
    else
      [
        { start: "#{date} 00:00:00".to_time,   end: "#{date} 23:59:59".to_time,   market: 'cn' }
      ]
    end
  end
end
