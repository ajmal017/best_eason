# 每天实际指数计算：排除cash之后，矫正过的比例
class BasketIndex::RealWithoutCash < BasketIndex::Real

  private
  def get_stock_weights
    weights = basket.initial_stock_weights_by_date(date)
    Basket.adjust_weights_exclude_cash(weights)
  end

  def last_day_index(last_index_record)
    last_index_record.index_without_cash
  end

  def set_adjusted_weights
    # do nothing
  end

end