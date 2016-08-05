# 账户持仓风险分析
class AccountPositionRisk < ActiveRecord::Base
  validates :trading_account_id, presence: true, :uniqueness => { :scope => :date }

  belongs_to :trading_account
  has_many :positions, -> { where("positions.currency is not null") }, foreign_key: :trading_account_id, primary_key: :trading_account_id
  
  # 高风险
  RISK_HIGH = 1
  # 中风险
  RISK_MEDIUM = 3
  # 低风险
  RISK_LOW = 5
  
  # high default:80 low default: 50
  RISK_LEVEL_CONDITIONS = {
    RISK_HIGH   => ->(v, high = 80, low = 50){ v >= high },
    RISK_MEDIUM => ->(v, high = 80, low = 50){ v >= low and v < high },
    RISK_LOW    => ->(v, high = 80, low = 50){ v < low }
  }

  # 个股集中度等级(高中低) 80%以上高 80-60%中 40%低
  def stock_focus_level
    self.class.level_code(stock_focus_score)
  end

  # 行业集中度（最大行业的权重，建议减仓最大行业的股票）
  def industry_focus_level
    self.class.level_code(industry_focus_score)
  end

  # 板块集中度 (中小板创业板比重)
  def plate_focus_level
    self.class.level_code(plate_focus_score)
  end

  # 组合波动等级
  def basket_fluctuation_level
    self.class.level_code(basket_fluctuation, 35, 20) 
  end

  # 综合指标,就是把前面4个指标取个平均.高1分,中3分,低5分.4-5分低风险,3－4分中风险,《3分，低风险。
  def average_level
    return RISK_LOW if average_score >= 4

    average_score < 3 ? RISK_HIGH : RISK_MEDIUM
  end

  def average_score
    @average_score ||= (stock_focus_level + industry_focus_level + plate_focus_level + basket_fluctuation_level) / 4.0
  end

  def as_mobile_json
    {
      stock_level:              stock_focus_level,
      industry_level:           industry_focus_level,
      plate_level:              plate_focus_level,
      basket_fluctuation_level: basket_fluctuation_level,
      basket_var95_score:       var95.to_f.round(2),
      basket_var95_unit:        trading_account.cash_unit,
      average_score:            (average_score * 20).to_f.round(2),
      average_level:            average_level
    }
  end

  def self.level_code(value, high = 80, low = 50)
    RISK_LEVEL_CONDITIONS.each do |code, condition|
      break code if condition.call(value, high, low)
    end
  end
  
  def self.risk_result_for(account_id)
    record = where(trading_account_id: account_id).order(date: :desc).first
    return {} unless record.present?

    record.as_mobile_json
  end

  # 获取最新的账户风险对象
  def self.get(account_id)
    new(trading_account_id: account_id)
  end

  ###########################SCORE计算使用############################
  def self.update_score(trading_account_id, date = Date.today)
    risk = find_or_create_by(trading_account_id: trading_account_id, date: date)
    risk.update(risk.as_rt_score_json)
  end

  def as_rt_score_json
    {
      stock_focus_score:    rt_stock_focus_score,
      industry_focus_score: rt_industry_focus_score,
      plate_focus_score:    rt_plate_focus_score,
      var95:                calculate_var95,
      basket_fluctuation:   trading_account.user.try(:basket_fluctuation)
    }
  end

  # 个股集中度 （高的化，建议分散投资，减仓重仓股）权重最大的三只股票的和
  def rt_stock_focus_score
    return 0 if total_property.zero?
    
    stock_values.map(&:last).sort.reverse[0, 3].sum.to_f.fdiv(total_property) * 100
  end

  # 一级行业集中度
  def rt_industry_focus_score
    return 0 if total_property.zero?

    sectors = position_stocks.map{|s|[s.id, s.sector_code]}.to_h
    
    value = stock_values.map{ |item| [sectors[item.first], item.last]}.group_by(&:first).map do |sector_code, values|
      values.sum(&:last)
    end.max.to_f

    value.fdiv(total_property) * 100
  end

  # 板块集中度(中小板创业板),目前只有A股
  def rt_plate_focus_score
    return 0 if total_property.zero?

    stock_ids = position_stocks.select{|s|s.listed_sector_risk_high?}.map(&:id)

    value = stock_values.inject(0) do |sum, item|
      stock_ids.include?(item.first) ? (sum + item.last) : sum
    end

    value.fdiv(total_property) * 100
  end

  def stock_values
    @values ||= positions.map{|p| [p.base_stock_id, p.shares * Rs::Stock.new(p.base_stock_id).realtime_price * Currency.transform(p.currency, trading_account.base_currency)] }.group_by(&:first).map do |stock_id, items|
      [stock_id, items.sum(&:last).to_f]
    end
  end

  def position_stocks
    @stocks ||= BaseStock.where(id: positions.map(&:base_stock_id))
  end

  def total_property
    @total_property ||= trading_account.total_property
  end

  # 组合VaR95(Value at Risk)
  # VaR一般被称为"风险价值"或"在险价值"，指在一定的置信水平下，组合在未来特定的一段时间内的最大可能损失。
  # 我们计算的是VaR95，也就是在95%的情下，组合的最大损失不会大于这个数字。比如数字是¥1000，表示你的组合损失大约¥1000的概率小于5%。
  def calculate_var95
    quote_classes = position_stocks.map{|s|[s.id, s.historical_quote_class]}.to_h

    data = []
    positions.each do |p|
      quotes = quote_classes[p.base_stock_id].select("last, date, currency").where(base_stock_id: p.base_stock_id).where("date >= ? and volume > 0", 1.year.ago).order(date: :desc)
      quotes.each_cons(2).each do |previous, current|
        data << [current.date, (current.last - previous.last) * p.shares * Currency.transform(current.currency, trading_account.base_currency)]
      end
    end

    result = data.group_by(&:first).map{|date, item| item.map(&:last).sum}.sort
    result[[(result.size * 5 / 100) - 1, 0].max]
  end

end
