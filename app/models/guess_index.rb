class GuessIndex < ActiveRecord::Base
  belongs_to :user

  validates :index, presence: true
  validates :user_id, uniqueness: {scope: :date}

  validate :check_valid

  def self.set(user, market_index)
    guess_index = self.find_or_initialize_by(user_id: user.id, date: next_latest_trade_date)
    guess_index.update(index: market_index)
    if guess_index.errors.messages.present?
      {status: false, msg: guess_index.errors.messages.values.first}
    else
      {status: true}
    end
  end

  def self.guessed?(user)
    self.where(user_id: user.try(:id), date: next_latest_trade_date).present?
  end

  def prev_index
    @prev_index ||= self.class.final_index(prev_workday)
  end

  def self.prev_index
    new(date: next_latest_trade_date).prev_index
  end

  def prev_workday
    ClosedDay.get_work_day(date-1, :cn)
  end

  def in_range?
    index.between?(prev_index*0.9, prev_index*1.1)
  end

  def self.exchange
    Exchange::Base.by_area(:cn)
  end

  def self.chart_datas_with_user(user_id, date = nil)
    date ||= next_latest_trade_date
    index = find_by(user_id: user_id, date: date).try(:index)
    datas = chart_datas(date).map do |data|
      index >= data[:min] && index < data[:max] ? data.merge!(active: 1) : data
    end
    {datas: datas, user_index: index}
  end

  def self.chart_datas(date = nil)
    date ||= next_latest_trade_date
    grouped_indices = self.where(date: date).select("`index` DIV 50 as g_value, count(*) as total").group(:g_value)
    grouped_indices.map do |g_data|
      min = g_data.g_value*50
      max = (g_data.g_value+1)*50
      g_name = "#{min}~#{max}"
      {name: g_name, count: g_data.total, min: min, max: max}
    end.sort_by{|x| x[:max] }.reverse
  end

  def self.nearest_records(date, final_index)
    self.where(date: date).select("ABS(`index` - #{final_index}) as diff_val, user_id, `index`, updated_at")
        .order("diff_val asc, updated_at asc").limit(3)
  end

  def self.final_index(date)
    index = HistoricalQuotePrice.find_by(base_stock_id: BaseStock.sh.id, date: date).try(:last)
    index || BaseStock.sh.realtime_price
  end

  private

  def check_valid
    errors.add(:game_over, "活动已结束！") if Time.now >= Time.parse("2015-09-18 09:00:00")
    errors.add(:trading, "还没收盘，15点后再来吧！") if trading?
    errors.add(:out_of_range, "竞猜范围不得超过±10%，再试试吧！") unless in_range?
  end

  def self.next_latest_trade_date
    exchange.latest_market_date
  end

  def trading?
    self.class.exchange.trading?
  end

end