class Investment

  def self.popular_position_stocks(account)
    BaseStock.where(id: $redis.hget(popular_stocks_key, account.broker_id).split(',')) rescue []
  end

  # 每日定时同步持仓最多的个股
  def self.sync_popular_stocks
    $redis.del(popular_stocks_key)

    foreign_stock_ids = Position.select("base_stock_id, count(*) as count_stock_id, market").where(market: ['hk','us']).group(:base_stock_id).order("count_stock_id desc").limit(5).map(&:base_stock_id)

    if foreign_stock_ids.present?
      results = Broker.where(name: ['ib', 'unicorn']).map{|b| [b.id, foreign_stock_ids.join(',')]}.to_h
      $redis.mapped_hmset(popular_stocks_key, results)
    end

    cn_stock_ids = Position.select("base_stock_id, count(*) as count_stock_id, market").where(market: 'cn').group(:base_stock_id).order("count_stock_id desc").limit(5).map(&:base_stock_id)
    if cn_stock_ids.present?
      results = Broker.where.not(name: ['ib', 'unicorn']).map{|b| [b.id, cn_stock_ids.join(',')]}.to_h
      $redis.mapped_hmset(popular_stocks_key, results)
    end
  end

  def self.popular_stocks_key
    "investment:popular_stock_ids"
  end
  
  # [account的胜率, broker下面所有account平均胜率]
  def self.winning_ratio(account)
    [ $redis.hget(winning_key, account.id).to_f, $redis.hget(broker_winning_key, account.broker_id).to_f ]
  end

  # 多账号同步投资胜率
  def self.sync_winning_ratio
    clear_winning_cache

    OrderSell.where(status: ['completed', 'partial_completed']).includes(:order_details).group_by(&:trading_account_id).each do |trading_account_id, orders|
      orders = orders.reject{|o| o.order_details.any?{|od| od.average_cost.zero?}}
      percent = orders.size.zero? ? 0 : orders.to_a.select{|o| o.real_profit.to_f > 0}.size.fdiv(orders.size) * 100
      $redis.mapped_hmset(winning_key, {trading_account_id => percent})
    end

    # 用户平均胜率ib和unicorn合并，a股按照券商来统计
    foreign_broker_ids = Broker.where(name: ['ib', 'unicorn']).map(&:id)
    foreign_rates = []

    TradingAccount.select("id, broker_id").where(id: $redis.hkeys(winning_key)).group_by{|a|a.broker_id}.map do |broker_id, accounts|
      percents = $redis.hmget(winning_key, accounts.map(&:id))
      if foreign_broker_ids.include?(broker_id)
        foreign_rates << percents
      else
        $redis.mapped_hmset(broker_winning_key, {broker_id => percents.average})
      end
    end

    $redis.mapped_hmset(broker_winning_key, foreign_broker_ids.map{|broker_id| [broker_id, foreign_rates.flatten.average]}.to_h)
  end

  def self.winning_key
    "investment:winning_ratio"
  end

  def self.broker_winning_key
    "investment:broker_winning"
  end

  def self.clear_winning_cache
    $redis.del(winning_key)
  end

  # 行业投资比例
  def self.sector_ratio(account)
    sector_percents = $cache.hread(sector_key, account.id)
    sector_percents.map{|k, v| {name: Sector::MAPPING[k.to_s] || '其它', rate: v[:rate], color: Sector::COLORS[k.to_s] || Sector::COLORS["-1"], value: v[:value]}}
  rescue
    []
  end

  def self.clear_sector_ratio(user_id = nil)
    user_id.present? ? $redis.hdel(sector_unicorn_key, user_id) : $redis.del(sector_unicorn_key)
  end

  # 同步行业投资比例
  def self.sync_sector_ratio
    Position.select("distinct(trading_account_id)").map(&:trading_account_id).each do |account_id|
      stock_id_shares = Position.where(trading_account_id: account_id).map{|x| [x.base_stock_id, x.shares.to_i]}

      results = {}
      BaseStock.where(id: stock_id_shares.map(&:first)).group_by(&:sector_code).map do |sector_code, stocks|
        sector_values = stocks.sum do |bs|
          position_count = stock_id_shares.select{|x| x.first == bs.id}.sum(&:last)
          begin
            rt_price = bs.realtime_price_with_usd
          rescue Exception => e
            Caishuo::Utils::Email.deliver(Setting.investment_notifiers.email, Rails.env, "投资概览持仓行业比例计算出错:#{e.message}")
            rt_price = 0
          end
          position_count * rt_price
        end

        results.merge!({sector_code => sector_values}) if sector_code && sector_values > 0
      end
      percents = results.map{|k, v| [k, {rate: v.fdiv(results.values.sum), value: v}]}.sort_by{|x| x.last[:value]}.reverse

      # 其它行业比例
      if percents.size >= 6
        ratios = percents[0..4].push [-1, {rate: percents[5..-1].sum{|x| x.last[:rate]}.to_f, value: percents[5..-1].sum{|x| x.last[:value]}.to_f}]
      else
        ratios = percents[0..4]
      end

      $cache.hwrite(sector_key, account_id, ratios.to_h)
    end
  end

  def self.sector_key
    "investment:sector_percent"
  end
  
  # 清除空仓账户的行业投资比例
  def self.clear_expired_sector_ratio
    Redis.current.hkeys(sector_key).each do |account_id|
      has_position = Position.where(trading_account_id: account_id).where("shares > 0").exists?
      unless has_position
        Redis.current.hdel(sector_key, account_id)
      end
    end
  end

  def self.profit_fluctuation(account)
    $redis.hget(profit_fluctuation_key, account.id).to_f
  end

  # 收益波动
  def self.sync_profit_fluctuation
    $redis.del(profit_fluctuation_key)

    UserProfit.select("distinct(trading_account_id)").each do |user_profit|
      rets = [0]
      UserProfit.where(trading_account_id: user_profit.trading_account_id).where("date >= ?", 1.month.ago).order(date: :asc).each_cons(2) do |previous_profit, profit|
        rets << (profit.total_pnl - previous_profit.total_pnl).fdiv(previous_profit.total_pnl.abs).round(3) unless previous_profit.total_pnl.zero?
      end
      unless rets.standard_deviation.zero?
        $redis.mapped_hmset(profit_fluctuation_key, {user_profit.trading_account_id => rets.standard_deviation})
      end
    end

    fluctuations = $redis.hgetall(profit_fluctuation_key).sort_by{|k,v| v.to_f }
    fluctuations.each_with_index do |element, index|
      $redis.mapped_hmset(profit_fluctuation_key, {element.first => index.fdiv(fluctuations.count) * 180})
    end
  end

  def self.profit_fluctuation_key
    "investment:fluctuation"
  end

  # 用户平均每月回报
  def self.one_month_return(type)
    $redis.hget(one_month_return_key, type).to_f
  end

  # 用户平均一月回报
  def self.sync_one_month_return
    clear_one_month_return_cache
    accounts = TradingAccount.active.map{|account| [account.id, {type: account.type, base_currency: account.base_currency}]}.to_h
    returns = TradingAccount.select("distinct(type)").map{|account| [account.type, {profit: 0, property: 0}]}.to_h
    UserProfit.select("trading_account_id, total_pnl, date").where("date >= ?", 30.days.ago).group_by(&:trading_account_id).map do |account_id, ps|
      next unless accounts.key?(account_id)
      account = accounts[account_id]
      returns[account[:type]][:property] += Position.total_property_for(account_id) * Currency.transform(account[:base_currency], 'USD')
      returns[account[:type]][:profit] += ([ps.minmax_by{|x|x.date}].map{|min, max| max.total_pnl - min.total_pnl}.first)
    end
    percents = returns.map{|k, v| [k, (v[:profit].fdiv(v[:property]) * 100 rescue 0).to_f.round(2)] }.to_h
    $redis.mapped_hmset(one_month_return_key, percents)
  rescue Exception => e
    Caishuo::Utils::Email.deliver(Setting.investment_notifiers.email, Rails.env, "用户每月回报计算出错:#{e.message}")
  end

  def self.one_month_return_key
    "investment:one_month_return"
  end

  def self.clear_one_month_return_cache
    $redis.del(one_month_return_key)
  end

  # 用户平均换手率
  def self.average_turnover_rate
    $cache.fetch(average_turnover_key, :expires_in => 1.hours) do
      currency = Currency::Base.new('USD')

      trading_cost = OrderDetail.where("trade_time >= ?", 30.days.ago).profited.inject(0) do |sum, od|
        sum + od.real_cost.to_f * currency.rate(od.currency)
      end

      total_market_value = Position.select("base_stock_id, shares, currency").valid_currency.inject(0) do |sum, p|
        sum + p.shares * ::Rs::Stock.new(p.base_stock_id).realtime_price * currency.rate(p.currency)
      end

      trading_cost.fdiv(total_market_value + AccountValue.whole_cash) * 100
    end
  end

  def self.average_turnover_key
    "investment:average_turnover"
  end

  def self.clear_average_turnover
    $redis.del(average_turnover_key)
  end

  # 30天内用户平均仓位
  def self.one_month_user_average_position
    $redis.get(user_average_position_key).to_f
  end

  # 30天用户平均仓位
  def self.sync_30days_average_position
    percents = UserDayProperty.where(date: 30.days.ago..Date.today).inject([]) do |ret, property|
      rate = property.total.zero? ? 0 : (property.total - property.total_cash).fdiv(property.total) * 100
      ret.push rate
    end

    $redis.set(user_average_position_key, percents.average)
  end

  def self.user_average_position_key
    "investment:average_position"
  end

  def self.property_rank(account_id)
    cutoff_date = Time.now.hour >= 9 ? Date.today : Date.yesterday

    user_id = TradingAccount.find(account_id).try(:user_id)

    redis_key = property_rank_key(cutoff_date, account_id)
    # 超越人数 落后人数
    beyond, behind = $redis.zrank(redis_key, user_id).to_i, $redis.zrevrank(redis_key, user_id).to_i
    # 前进位数
    forward = $redis.zrevrank(property_rank_key(cutoff_date - 1, account_id), user_id).to_i - behind

    {beyond: beyond, behind: behind, forward: forward, winning: property_winning_percent(account_id)}
  end

  # 同步好友净值回报排名
  def self.sync_friends_property_rank
    TradingAccount.active.find_each do |account|
      properties = UserDayProperty.account_friends_30days_return(account)
      $redis.zadd(property_rank_key(Date.today, account.id), properties)
    end

    clear_property_rank_cache!
  end

  def self.clear_property_rank_cache!
    (10.days.ago.to_date..3.days.ago.to_date).each do |date|
      $redis.keys("investment:property_rank:#{date.to_s(:db)}*").each{|key| $redis.del(key)}
    end
  end

  def self.property_rank_key(date, account_id)
    "investment:property_rank:#{date.to_s(:db)}:#{account_id}"
  end

  def self.property_winning_percent(account_id)
    beyond, total = $redis.zrank(total_property_rank_key, account_id).to_i, $redis.zcard(total_property_rank_key)

    total.zero? ? 0 : (beyond.fdiv(total) * 100).round(2)
  end

  def self.sync_total_property_rank
    ranks = []
    UserDayProperty.where("date >= ?", 31.days.ago).available.group_by(&:trading_account_id).map do |trading_account_id, properties|
      base, current = properties.minmax_by{|p|p.date}.map{|p| p.usd_total}
      score = base.zero? ? 0 : current.fdiv(base) - 1.0
      ranks.push [score, trading_account_id]
    end

    $redis.zadd(total_property_rank_key, ranks.flatten)
  end

  def self.total_property_rank_key
    "investment:total_property_rank"
  end

end
