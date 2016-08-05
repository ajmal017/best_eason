class BasketIndex < ActiveRecord::Base
  TIME_PEROID_DAYS_HASH = {"1周" => 8, "1月" => 30, "3月" => 91, "6月" => 182, "1年" => 366, "5年" => 1825}
  
  belongs_to :basket
  
  scope :by_basket, ->(basket_id) { where(basket_id: basket_id) }
  scope :date_between, ->(start_day, end_day) { where(date: start_day..end_day) }
  scope :desc_id, -> { order(id: :desc) }
  scope :by_date, ->(day) { where(date: day) }

  def self.get_basket_indices(basket_id, start_date, end_date)
    basket_indices = self.where(:basket_id => basket_id).where("date >= ? and date <= ?", start_date, end_date).order(:date)
    basket_indices.map{|b| [b.date.to_s(:db), b.index.to_f.round(3)]}.sort_by{|x| x[0]}
  end

  #计算并记录index到db
  def self.record_index(basket_id, date)
    basket = Basket.find_by_id(basket_id)
    return false unless valid_for_cal_index?(basket, date)

    basket_index = BasketIndex::Real.new(basket, date).calculate
    # 不包含cash的指数，暂且无用
    # index_without_cash = BasketIndex::RealWithoutCash.new(basket, date).calculate
    
    set_day_index(basket, date, basket_index) if basket_index
  end
  
  def self.record_index_yesterday(basket_id)
    record_index(basket_id, Date.today - 1)
  end
  
  def self.set_day_index(basket, date, basket_index)
    ActiveRecord::Base.transaction do
      today_basket_index = basket.basket_indices.find_or_create_by(date: date)
      today_basket_index.update(index: basket_index)
    end
  end

  def self.get_index_near_date(basket_id, date)
    by_basket(basket_id).date_between(date - 7.days, date).desc_id.first.try(:index)
  end

  def self.get_index_by(basket_id, date)
    self.where(:basket_id => basket_id, date: date).first.try(:index)
  end

  def self.first_basket_index(basket_id)
    self.where(:basket_id => basket_id).order("date").first
  end

  def self.lastest_basket_index(basket_id)
    self.where(:basket_id => basket_id).order("date desc").first
  end

  #根据时间段返回开始日期
  def self.start_date_by_time_period(time_period, market_area = :us)
    days = BasketIndex::TIME_PEROID_DAYS_HASH[time_period]
    days.present? ? ClosedDay.get_work_day_after(Date.today - days, market_area) : nil
  end

  def ret_from_start
    (index - 1000)/1000 rescue 0
  end
  
  private
  def self.valid_for_cal_index?(basket, date)
    (basket.present? && (basket.completed? || basket.archived?)) && ClosedDay.is_workday?(date, basket.market)
  end
end
