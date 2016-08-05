class Basket::History < Basket::Normal
  delegate :comments_count, :realtime_index, :change_percent, :order_basket_id, to: :original

  def is_history?
    true
  end

  def can_edit?
    false
  end

  def can_drop?
    false
  end

  def newest_version
    original
  end

  def comments
    original.comments
  end

  def created_in_trading?
    created_time = market=="us" ? created_at.in_time_zone('Eastern Time (US & Canada)') : created_at
    created_date = created_time.to_date
    return false unless ClosedDay.is_workday?(created_date, market)
    start_time, end_time = Exchange::Base.by_area(market).trade_time_range(created_date)
    created_at >= start_time && created_at <= end_time
  end

end
