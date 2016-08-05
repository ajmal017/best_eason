# 账户分析
class AccountAnalysis < ActiveRecord::Base
  serialize :holding_terms
  serialize :stock_earn
  serialize :stock_holded_days
  serialize :stock_spend
  serialize :industries
  serialize :market_distribution

  belongs_to :trading_account

  attr_accessor :date
  alias_attribute :account_id, :trading_account_id

  TERMS = { short: "短期", mid: "中期", long: "长期" }

  def self.cal(account_id, date)
    analysis = find_or_initialize_by(trading_account_id: account_id, year: date.year)
    analysis.date = date
    analysis.recal
  end

  # 0.05%
  def commission_rate
    trading_account.analog? ? 0.05 : "--"
  end

  def begin_time
    @begin_time ||= Time.local(year, 1, 1, 0, 0, 0)
  end

  def begin_date
    @begin_date ||= begin_time.to_date
  end

  def end_time
    @end_time ||= begin_time.at_end_of_year
  end

  def end_date
    @end_date ||= begin_date.end_of_year
  end

  def date
    @date || Date.yesterday
  end

  def all_years
    self.class.where(trading_account_id: trading_account_id).pluck(:year)
  end

  # 按年汇总
  # todo: position_archive archive时间提前
  def recal
    self.profit = cal_profit
    self.buy_count = OrderBuy.trade_between(account_id, begin_time, end_time).count
    self.sell_count = OrderSell.trade_between(account_id, begin_time, end_time).count
    self.avg_month_trade = cal_avg_month_trade
    self.cleared_stock_count = cal_cleared_stock_count
    self.win_rate = cal_win_rate
    self.earned_stocks_count = cal_earned_stocks_count
    self.lossed_stocks_count = cal_lossed_stocks_count
    self.avg_holded_days = cal_avg_holded_days
    self.holding_terms = cal_holding_terms
    self.stock_earn = cal_stock_earn_money
    self.stock_holded_days = cal_stock_holded_days
    self.stock_spend = cal_stock_spend_money
    self.total_buyed = OrderBuy.trade_between(account_id, begin_time, end_time).sum(:real_cost)
    self.total_selled = OrderSell.trade_between(account_id, begin_time, end_time).sum(:real_cost)
    self.industries = cal_invest_industries
    self.focus_industry = cal_focus_industry
    self.market_distribution = market_distribution_by_date
    self.orientation = trading_account.try(:user).try(:profile).try(:orientation)
    self.concern = trading_account.try(:user).try(:profile).try(:concern)
    self.save!
    self
  end

  def web_datas
    {
      year: year,
      year_list: all_years,
      shareurl: trading_account.analysis_snapshot_url(year),
      user_name: trading_account.user.try(:username),
      avatar: trading_account.user.try(:avatar_url, :large),
      aggregate: {
        profit: profit,
        buy_cnt: buy_count,
        sell_cnt: sell_count,
        buy: total_buyed,
        sell: total_selled,
        total: total_buyed + total_selled
      },

      trading_cnt_monthly: avg_month_trade, # 月均交易次数
      industry_focused: focus_industry, # 重点关注行业
      type_preferred: preferred_term, # 投资分布/类型
      clear_stocks_cnt: cleared_stock_count, # 清仓股票, 200只
      earn_stocks_cnt: earned_stocks_count, # 挣钱股票, 100只
      loss_stocks_cnt: lossed_stocks_count, # 赔钱股票, 10只
      win_rate: win_rate,
      commission_rate: commission_rate, # 佣金,
      hold_time_avg: avg_holded_days, # 平均持有时间, e.g. 3天

      holding_terms: formated_holding_terms,
      top: {
        net_change_max: stock_earn[:max],
        net_change_min: stock_earn[:min],
        hold_time_max: stock_holded_days[:max],
        hold_time_min: stock_holded_days[:min],
        amount_max: stock_spend[:max],
        amount_min: stock_spend[:min]
      },

      analysis: {
        main_plate: main_plate_holding, # 主板, e.g. 221.00万
        gem_plate: gem_plate_holding, # 创业板（growth enterprise market）, e.g. 20.21万
        concerns: concern, # 投资关注
        orientation: orientation, # 投资方向
        pie_data: industries # 投资分布图
      }
    }
  end

  def formated_holding_terms
    sum = holding_terms.values.sum || 0
    holding_terms.sort_by { |_, c| c }.reverse.map do |type, count|
      { type: type, count: count, percent: Caishuo::Utils::Helper.div_percent(count, sum) }
    end
  end

  def preferred_term
    max_term = holding_terms.sort_by { |_, c| c }.last
    max_term.last.zero? ? "--" : TERMS[max_term.first]
  end

  def main_plate_holding
    plate_holding_by("主板") || (plate_holding_by("美股").to_f + plate_holding_by("港股").to_f)
  end

  def gem_plate_holding
    plate_holding_by("创业板") || 0
  end

  def plate_holding_by(name)
    market_distribution.find { |x| x[:name] == name }.try(:[], :amount)
  end

  private

  def buyed_stock_ids
    @buyed_stock_ids ||= OrderBuy.select("distinct order_details.base_stock_id").by_account(account_id).traded
                         .joins(:order_details).where("trade_time >= ? and trade_time <= ?", begin_time, end_time).map(&:base_stock_id)
  end

  def cal_profit
    # UserDayProperty.profit_between(account_id, begin_date, end_date)
    stock_profits.map { |_, profit| profit }.sum || 0
  end

  def cal_avg_month_trade
    months = if year == trading_account.created_at.year
               date.month - trading_account.created_at.month + 1
             else
               date.month
             end
    ((buy_count + sell_count) / months.to_f).round(1)
  end

  # 一年购买过的总数、现在持仓、"--"
  def cal_focus_industry
    BaseStock.where(id: buyed_stock_ids).group(:sector_code).select("count(1), sector_code").order("count(1) desc").first.try(:sector_name) ||
      industries.sort_by(&:last).last.try(:first) || "--"
  end

  def cal_cleared_stock_count
    diff_count = holding_days.size - trading_account.positions.size
    diff_count < 0 ? 0 : diff_count
  end

  def cal_win_rate
    return 0 if sell_count.zero?

    winned_count = OrderSell.by_account(account_id).traded.joins(:order_details).where("trade_time >= ? and trade_time <= ?", begin_time, end_time)
                   .map(&:real_profit).compact.count { |x| x > 0 }
    (winned_count * 100 / sell_count).to_i
  end

  def position_archives
    @position_archives ||= PositionArchive.account_with(account_id).date_between(begin_date, end_date).pluck(:base_stock_id, :archive_date)
  end

  def holding_days
    @holding_days ||= holding_days_by_details_block.call
  end

  # 根据order_details、exec_details等推算持仓天数
  def holding_days_by_details_block
    lambda do
      days = []
      archive_shares = PositionArchive.account_with(account_id).where(archive_date: begin_date - 1).pluck(:base_stock_id, :shares).to_h
      order_details = account_order_details.select(:base_stock_id, :real_shares, :trade_time, :trade_type)

      (order_details + account_exec_details).group_by(&:base_stock_id).each do |stock_id, details|
        now_shares = archive_shares[stock_id] || 0
        prev_date = begin_date
        details.sort_by(&:trade_time).each do |detail|
          prev_date = detail.trade_time.to_date if now_shares.zero?
          now_shares += detail.real_shares * detail.trading_flag
          days << [stock_id, (detail.trade_time.to_date - prev_date).to_i + 1] if now_shares.zero?
        end
        days << [stock_id, (date - prev_date).to_i + 1] if now_shares > 0
      end
      days
    end
  end

  # 短线<15 中线15-90 长线>90
  def cal_holding_terms
    short, mid, long = 0, 0, 0
    holding_days.each do |_, day|
      if day < 15
        short += 1
      elsif day > 90
        long += 1
      else
        mid += 1
      end
    end
    { short: short, mid: mid, long: long }
  end

  def cal_avg_holded_days
    return nil if holding_days.size.zero?
    (holding_days.map(&:last).sum / holding_days.size).round(1)
  end

  def cal_stock_holded_days
    sorted_days = holding_days.sort_by(&:last)
    return { min: {}, max: {} } if sorted_days.size.zero?
    { min: stock_item(*sorted_days.first), max: stock_item(*sorted_days.last) }
  end

  # 个股整年的holding+trading利润
  # 数组格式：[stock_id, profit(根据account的base_currency转换后利润)]
  def stock_profits
    @stock_profits ||= lambda do
      (stocks_holding_pnl + stocks_trading_pnl + exec_details_pnl).group_by(&:first).map do |stock_id, pnls|
        rate = currency_obj.rate(::Rs::Stock.find(stock_id).currency)
        [stock_id, pnls.map(&:last).sum * rate]
      end.sort_by(&:last)
    end.call
  end

  def stocks_holding_pnl
    PositionArchive.account_with(account_id).where(archive_date: begin_date - 1).map do |p|
      profit = p.shares * p.base_stock.price_changed_by(begin_date)
      [p.base_stock_id, profit]
    end
  end

  def stocks_trading_pnl
    account_order_details.group_by(&:base_stock_id).map do |stock_id, order_details|
      profit = order_details.map do |od|
        price = price_by(stock_id, od.trade_time.to_date, od.historical_klass, od.realtime_price)
        (price * od.real_shares.to_i - od.real_cost.to_f) * od.trading_flag - od.commission.to_f
      end.sum
      [stock_id, profit]
    end
  end

  def exec_details_pnl
    return [] unless trading_account.is_a? TradingAccountEmail

    TwsExec.account_with(account_id).time_between(begin_time, end_time).group_by(&:stock_id).map do |stock_id, exec_details|
      profit = exec_details.map do |ex|
        price = price_by(stock_id, ex.created_at.to_date, HistoricalQuote, ex.realtime_price)
        (price - ex.avg_price) * ex.shares.to_i * ex.trading_flag
      end.sum
      [stock_id, profit]
    end
  end

  def price_by(stock_id, price_date, historical_klass, now_price)
    price = HistoricalQuotePrice.price_by(stock_id, date)
    price = now_price if price.zero?
    price * HistoricalQuotePrice.price_ratio(stock_id, price_date, historical_klass)
  end

  def cal_earned_stocks_count
    stock_profits.count { |_, profit| profit >= 0 }
  end

  def cal_lossed_stocks_count
    stock_profits.count { |_, profit| profit < 0 }
  end

  def cal_stock_earn_money
    stock_min_max_datas(stock_profits)
  end

  def cal_stock_spend_money
    stock_costs = account_order_details.buyed.select("base_stock_id, sum(real_cost) as cost")
                  .group(:base_stock_id).map { |x| [x.base_stock_id, x.cost] }.sort_by { |x| x[1] }
    stock_min_max_datas(stock_costs)
  end

  def account_order_details
    OrderDetail.fill_finished.account_with(account_id).trade_time_range(begin_time, end_time)
  end

  # 美股、港股账户返回正常结果，A股返回空
  def account_exec_details
    return [] unless trading_account.is_a? TradingAccountEmail
    TwsExec.account_with(account_id).time_between(begin_time, end_time).select(:stock_id, :shares, :side, :time).map do |exec_detail|
      OpenStruct.new(
        base_stock_id: exec_detail.stock_id, trade_time: Time.parse(exec_detail.time),
        real_shares: exec_detail.shares, trading_flag: exec_detail.trading_flag
      )
    end
  end

  def stock_min_max_datas(analyse_datas)
    return { min: {}, max: {} } if analyse_datas.size.zero?
    { min: stock_item(*analyse_datas.first), max: stock_item(*analyse_datas.last) }
  end

  def stock_item(stock_id, amount)
    stock = BaseStock.find_by(id: stock_id)
    { stock_id: stock_id, name: stock.try(:com_name), symbol: stock.try(:symbol), value: amount.to_f }
  end

  def cal_invest_industries
    industry_infos = industries_by_date
    return [] if industry_infos.size.zero?
    total_value = industry_infos.map { |x| x[:value] }.sum
    industry_infos.map { |x| [x[:name], (x[:value] * 100 / total_value).round(1)] }
  end

  # 当计算往年数据时，不能使用当前的投资比例，现在使用最后一天archive的position数据
  def industries_by_date
    return Investment.sector_ratio(trading_account) unless diffirent_year?

    ending_day_positions.group_by {|pa| pa.base_stock.sector_code }.map do |code, positions|
      value = positions.map { |p| p.shares * HistoricalQuotePrice.price_by(p.base_stock_id, end_date) * currency_obj.rate(p.currency) }.sum
      { name: Sector::MAPPING[code.to_s], value: value }
    end
  end

  def market_distribution_by_date
    return Position.sector_market_value(trading_account) unless diffirent_year?

    group_block = trading_account.market_cn? ? proc {|x| x.base_stock.listed_sector_name} : proc {|x| x.base_stock.market_area_name}
    grouped_position_values(group_block).map do |name, total|
      { amount: total, name: name }
    end
  end

  def grouped_position_values(group_condition)
    ending_day_positions.group_by(&group_condition).map do |group_value, positions|
      total = positions.map do |p|
        p.shares * HistoricalQuotePrice.price_by(p.base_stock_id, end_date) * currency_obj.rate(p.currency)
      end.sum
      [group_value, total]
    end.to_h
  end

  def currency_obj
    @currency_obj ||= Currency::Base.new(trading_account.base_currency)
  end

  # 一年中最后一天的position_archives
  def ending_day_positions
    @ending_day_positions ||= PositionArchive.includes(:base_stock).account_with(trading_account_id).date_with(end_date)
  end

  def diffirent_year?
    year != Time.now.year
  end
end
