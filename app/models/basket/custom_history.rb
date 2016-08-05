class Basket::CustomHistory < Basket
  def costomize_title
    title
  end

  def can_edit?
    false
  end

  def is_history?
    true
  end

  def is_costomized?
    true
  end

  def can_drop?
    false
  end

  def can_init_first_day_index?
    (completed? || archived?) && basket_indices.blank?
  end

  def weight_changed?(date)
    false
  end

  def first_day_stock_weights
    self.stock_ori_weights
  end

  def newest_version
    self
  end

  def order_basket_id
    id
  end

  # blank
  def history_baskets_by(date)
    []
  end
end