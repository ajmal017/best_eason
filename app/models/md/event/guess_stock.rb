# 万圣节活动，猜个股
class MD::Event::GuessStock
  include Mongoid::Document
  include Mongoid::Timestamps

  field :date, type: Date
  field :user_id, type: Integer
  field :base_stock_id, type: Integer
  field :symbol
  field :name
  field :final_percent, type: Float  # 当天最终涨幅
  field :winned, type: Boolean, default: false # 是否中奖

  DATES = %w(2015-10-30 2015-11-02 2015-11-03 2015-11-04 2015-11-05).first(5).map{|x| Date.parse(x)}

  belongs_to :user, index: true, class_name: "MD::User"

  scope :sort, ->{ order(final_percent: :desc, created_at: :asc) }

  def self.add(user, stock)
    guess_stock = self.find_or_initialize_by(date: now_date, user_id: user.id)
    guess_stock.update(base_stock_id: stock.id, symbol: stock.symbol, name: stock.com_name)
  end

  def self.guessed?(user_id, date)
    return false if user_id.blank?
    where(date: date, user_id: user_id).exists?
  end

  # 用户参与了至少一次
  def self.joined?(user_id)
    return false if user_id.blank?
    where(user_id: user_id).exists?
  end

  def self.now_date
    if exchange.workday?
      exchange.market_open? ? ClosedDay.get_work_day_after(Date.tomorrow) : Date.today
    else
      ClosedDay.get_work_day_after(Date.tomorrow)
    end
  end

  def self.exchange
    Exchange::Base.by_area(:cn)
  end

  def pretty_json
    as_json(only: [:name, :final_percent])
  end

  def self.user_guesses(user_id)
    where(user_id: user_id).map{|x| [x.date, x.pretty_json]}.to_h
  end

  def self.win_results
    where(winned: true).desc(:final_percent).includes(:user).group_by(&:date)
  end

  def self.cal_results
    guess_stock_ids = where(date: Date.today).distinct(:base_stock_id)
    guess_stock_ids.each do |sid|
      percent = ::Rs::Stock.find(sid).change_percent
      where(date: Date.today, base_stock_id: sid).update_all(final_percent: percent)
    end

    # ids = where(date: Date.today).where(:final_percent.gte => 9.91).sort.limit(5).map(&:id)
    # where(:id.in => ids).update_all(winned: true)
  end

end