class PositionArchive < ActiveRecord::Base
  belongs_to :base_stock
  
  # shares大于0的持仓
  scope :valid_shares, -> { where("shares > 0") }
  # currency 合法
  scope :valid_currency, -> { where.not(currency: nil) }

  scope :profited, -> { where("shares > 0").where.not(currency: nil) }

  # 从某个用户获得
  scope :by_user, -> (user_id) { where(user_id: user_id) }
  # 交易账号
  scope :account_with, -> (account_id) { where(trading_account_id: account_id) }
  # 归档日期
  scope :date_with, -> (date) { where(archive_date: date) }
  scope :date_between, ->(begin_date, end_date){ where("archive_date >= ? and archive_date <= ?", begin_date, end_date) }
  # 地区
  scope :market_with, -> (market_area) { market_area.present? ? where(market: market_area) : all }
  
  # 某个主题
  scope :instance_with, -> (instance_id) { where(instance_id: instance_id) unless instance_id.nil? }
  # 个股
  scope :stock_with, ->(stock_id) { where(base_stock_id: stock_id) unless stock_id.nil? }
  # 类型: 主题/个股
  scope :category_with, -> (opts) { instance_with(opts[:instance_id]).stock_with(opts[:stock_id]) }

  scope :cn, -> { where(market: 'cn') }
  scope :us, -> { where(market: 'us') }
  scope :hk, -> { where(market: 'hk') }

  belongs_to :trading_account

  def shares
    read_attribute(:shares).to_i
  end

  def close_price
    read_attribute(:close_price).to_f
  end
  
  def holding_cost
    shares.abs * close_price
  end

  def holding_profit
    shares * ::Rs::Stock.find(base_stock_id).cutoff_price_changed
  end

  def historical_klass
    return HistoricalQuote if ['us', 'hk'].include?(market.try(:downcase))
    
    HistoricalQuoteCn
  end

  def adjusted_shares
    read_attribute(:adjusted_shares) || shares
  end

  # 今日盈亏汇总
  def self.today_profit(account)
    pnls = [ holding_pnl(account), trading_pnl(account), exec_trading_pnl(account) ]
    
    if account.is_a?(TradingAccountSim)
      [pnls.sum(&:first) - today_commission(account), div_percent(pnls.sum(&:first), previous_property(account))]
    else
      [pnls.sum(&:first), div_percent(pnls.sum(&:first), pnls.sum(&:last))]
    end
  end

  # 今日交易手续费
  def self.today_commission(account)
    return 0 unless account.is_a?(TradingAccountSim)

    OrderDetail.where(trading_account_id: account.id, trade_time: [Date.today..Date.tomorrow - 1.second]).profited.sum("commission")
  end

  # 昨天的账户净值
  def self.previous_property(account)
    property = UserDayProperty.where(trading_account_id: account.id).where("date <= ?", account.cutoff_holding_date).order(date: :desc).first
    property.try(:total).to_f
  end

  # 总的盈亏
  # TODO ACCOUNT_ID
  def self.total_profit(account, current_profit = nil)
    current_profit, current_profit_percent = today_profit(account) if current_profit.blank?

    previous_profit(account) * Currency.transform('USD', account.base_currency) + current_profit
  end

  def self.previous_profit(account)
    profit = UserProfit.where(trading_account_id: account.id).where("date <= ?", account.cutoff_holding_date).order(date: :desc).first
    profit.try(:total_pnl).to_f
  end

  # 持仓主题每日收益以及变动
  def self.today_basket_profit(account, instance_id, stock_id = nil)
    exchange = Exchange::Base.by_area(Basket.find(instance_id).get_area)

    opts = {instance_id: instance_id, stock_id: stock_id}

    pnls = [
      holding_pnl(account, opts), trading_pnl(account, opts), 
      exec_trading_pnl(account, opts.merge(trade_time: exec_times_with(exchange)))
    ]
    
    currency = pms_base_currency(stock_id, exchange)
    [ pnls.sum(&:first) * Currency.transform(account.base_currency, currency), div_percent( pnls.sum(&:first), pnls.sum(&:last) )]
  end

 
  # 持仓个股每日收益以及每日变动
  def self.today_stock_profit(account, stock_id)
    exchange = Exchange::Base.by_area(BaseStock.find(stock_id).market_area)

    opts = {instance_id: 'others', stock_id: stock_id}

    pnls = [
      holding_pnl(account, opts), trading_pnl(account, opts),
      exec_trading_pnl(account, opts.merge(trade_time: exec_times_with(exchange))),
      commission_pnl(account, opts)
    ]

    currency = pms_base_currency(stock_id, exchange)
    [pnls.sum(&:first) * Currency.transform(account.base_currency, currency), div_percent( pnls.sum(&:first), pnls.sum(&:last) )]
  end

  def self.exec_times_with(exchange)
    [{start: exchange.exec_start_trade_time, end: exchange.exec_end_trade_time}]
  end

  # 批量计算持仓主题的今日收益
  def self.bubble_basket_profit(account, basket_ids)
    basket_currencies = Basket.where(id: basket_ids).map{|b|[b.id, b.base_currency]}.to_h
    
    opts = { instance_id: basket_ids, group: Proc.new{|x|x.instance_id} }
    
    pnls = [holding_pnl(account, opts), trading_pnl(account, opts), exec_trading_pnl(account, opts)].inject({}) do |ret, h|
      ret.merge!(h){|k, v1, v2| [v1, v2].transpose.map(&:sum) }
    end

    basket_ids.map do |basket_id|
      if pnl = pnls[basket_id]
        [basket_id, [pnl.first.to_f * Currency.transform(account.base_currency, basket_currencies[basket_id.to_i]), div_percent(pnl.first, pnl.last)]]
      else
        [basket_id, [0,0]]
      end
    end.to_h
  end
 
  def self.bubble_stock_profit(account, stock_ids)
    stock_currencies = BaseStock.where(id: stock_ids).map{|b|[b.id, b.base_currency]}.to_h
    
    opts = { instance_id: 'others', base_stock_id: stock_ids, group: Proc.new{|x|x.base_stock_id} }
    pnls = [holding_pnl(account, opts), trading_pnl(account, opts), exec_trading_pnl(account, opts), commission_pnl(account, opts)].inject({}) do |ret, h|
      ret.merge!(h){|k, v1, v2| [v1, v2].transpose.map(&:sum) }
    end

    stock_ids.map do |stock_id|
      if pnl = pnls[stock_id]
        [stock_id, [pnl.first.to_f * Currency.transform(account.base_currency, stock_currencies[stock_id.to_i]), div_percent(pnl.first, pnl.last)]]
      else
        [stock_id, [0,0]]
      end
    end.to_h
  end

  # 注意单位为account的base currency,如果需要转换在调用方法内进行
  def self.holding_pnl(account, opts={})
    ps = account_with(account.id).date_with(account.cutoff_holding_date).category_with(opts.symbolize_keys).profited
  
    return holding_block.call(ps, Currency::Base.new(account.base_currency)) unless opts[:group]

    ps.group_by(&opts[:group]).inject({}) do |pnls, ps_arr|
      pnls.merge!(ps_arr.first => holding_block.call(ps_arr.last, Currency::Base.new(account.base_currency)))
    end
  end

  # 如果trade_time为空则取account的默认产生收益的交易时间
  def self.trading_pnl(account, opts={})
    opts.reverse_merge!(trade_time: account.profit_trade_times)

    ods = OrderDetail.account_with(account.id).category_with(opts.symbolize_keys).where(*trade_time_scope(opts[:trade_time])).profited
    
    return trading_block.call(ods, Currency::Base.new(account.base_currency)) unless opts[:group]

    ods.group_by(&opts[:group]).inject({}) do |pnls, od_arr|
      pnls.merge!(od_arr.first => trading_block.call(od_arr.last, Currency::Base.new(account.base_currency)))
    end
  end

  def self.exec_trading_pnl(account, opts={})
    if account.is_a?(TradingAccountPassword)
      return opts[:group] ? {} : [0, 0]
    end

    opts.reverse_merge!(trade_time: account.profit_trade_times)
    
    exs = account.exec_class.account_with(account.id).category_with(opts.symbolize_keys).where(*exec_time_scope(opts[:trade_time])).profited

    return exec_block.call(exs, Currency::Base.new(account.base_currency)) unless opts[:group]

    exs.group_by(&opts[:group]).inject({}) do |pnls, ex_arr|
      pnls.merge!(ex_arr.first => exec_block.call(ex_arr.last, Currency::Base.new(account.base_currency)))
    end
  end

  # 手续费收益(结果应该为负值)
  # TODO 注意汇率 
  def self.commission_pnl(account, opts = {})
    return (opts[:group] ? {} : [0,0]) unless account.is_a?(TradingAccountSim)
    
    opts.reverse_merge!(trade_time: account.profit_trade_times)

    ods = OrderDetail.account_with(account.id).where(*trade_time_scope(opts[:trade_time])).profited
    
    return [ods.map(&:commission).sum.to_f * -1, 0] unless opts[:group]

    ods.group_by(&opts[:group]).inject({}) do |pnls, od_arr|
      pnls.merge!(od_arr.first => [od_arr.last.map(&:commission).sum.to_f * -1, 0])
    end
  end

  def self.holding_block
    Proc.new do |ps, currency|
      cost, profit = 0, 0
      ps.each do |p|
        profit += p.adjusted_shares * ::Rs::Stock.new(p.base_stock_id).cutoff_price_changed * currency.rate(p.currency)
        cost   += p.adjusted_shares.abs * ::Rs::Stock.new(p.base_stock_id).previous_close * currency.rate(p.currency)
      end
      [profit, cost]
    end
  end

  def self.trading_block
    Proc.new do |ods, currency|
      cost, profit = 0, 0
      ods.each do |od|  
        profit += (od.realtime_price * od.real_shares.to_i - od.real_cost.to_f) * od.trading_flag * currency.rate(od.currency)
        
        # 卖单不再计算进今日盈亏百分比的分母(做空的情况下会有问题,目前不支持做空)
        if od.sell?
          cost   += 0 
        else
          cost   += od.real_cost.to_f.abs * currency.rate(od.currency)
        end
      end

      [profit, cost]
    end
  end

  def self.exec_block
    Proc.new do |exs, currency|
      cost, profit = 0, 0
      
      exs.each do |ex|
        profit += (ex.realtime_price - ex.avg_price) * ex.shares.to_i * ex.trading_flag * currency.rate(ex.currency)
        cost   += ex.shares.to_i.abs * ex.avg_price * currency.rate(ex.currency)
      end
      [profit, cost]
    end
  end

  def self.trade_time_scope(ranges = nil)
    sql_arrs = ranges.inject([]) do |arr, h|
      arr << ["(trade_time >= ? and trade_time <= ? and market = ?)", h.values_at(:start, :end, :market)]
    end

    [sql_arrs.map(&:first).join(" OR "), sql_arrs.map(&:last)].flatten
  end

  def self.exec_time_scope(ranges)
    sql_arrs = ranges.inject([]) do |arr, h|
      arr << ["(time >= ? and time <= ?)", h.values_at(:start, :end)]
    end

    [sql_arrs.map(&:first).join(" OR "), sql_arrs.map(&:last)].flatten    
  end

  # MARKET参数SYMBOL类型(:us, :hk)
  # 注意A股归档不走此方法
  def self.daily_generate(market, archive_date)
    close_prices = stock_close_prices(market)

    Position.where(market: market).includes(:base_stock).find_in_batches(batch_size: 3000) do |ps|
      imports = ps.map do |p|
          other_attrs = { archive_date: archive_date, close_price:  close_prices[p.base_stock_id] }
          attrs = p.attributes.slice(*attribute_names).symbolize_keys.merge(other_attrs).except(:id, :created_at, :updated_at)
          
          self.new(attrs)
      end.compact

      self.import(imports, on_duplicate_key_update: %w(basket_id shares basket_mount average_cost pending_shares updated_by currency close_price)) if imports.present?
    end
  rescue Exception => e
    Caishuo::Utils::Email.deliver(Setting.investment_notifiers.email, Rails.env, "持仓归档出错了:#{market} #{archive_date} #{e.message}")
  end

  def self.stock_close_prices(market)
    stock_ids = Position.where(market: market).select("distinct(base_stock_id)").map(&:base_stock_id)

    historical_quote_klass = [:us, :hk].include?(market) ? HistoricalQuote : HistoricalQuoteCn

    stock_max_dates = historical_quote_klass.select("base_stock_id, max(date) as max_date").where(base_stock_id: stock_ids)
      .group(:base_stock_id).map{|q| [q.base_stock_id, q.max_date]}.to_h
    
    close_prices = {}
    stock_max_dates.group_by{|stock_id,date|date}.map do |date, stock_dates|
      close_prices.merge!(historical_quote_klass.where(base_stock_id: stock_dates.map(&:first), date: date).map{|q| [q.base_stock_id, q.last]}.to_h)
    end
    close_prices
  end
  
  # 更新已归档的a股新股闭式价格
  def self.update_archived_new_stock_close_prices(archive_date)
    PositionArchive.where(archive_date: archive_date, market: 'cn').where("close_price is null or close_price = 0").each do |pa|
      base_stock = pa.base_stock
      #if base_stock.trading_unlisted?
      pa.update(close_price: base_stock.realtime_price) 
      #end
    end
  end

  def self.pms_base_currency(stock_id, exchange)
    stock_id.present? ? BaseStock.find(stock_id).base_currency : exchange.base_currency
  end

  def self.div_percent(molecular, denominator)
    Caishuo::Utils::Helper.div_percent(molecular, denominator)
  end
end
