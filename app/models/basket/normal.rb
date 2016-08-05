# basket normal
class Basket::Normal < Basket
  belongs_to :latest_history, class_name: "Basket", foreign_key: :latest_history_id

  # record_log：默认true
  # false情况：每日早上检测盘前调仓是否合法，不合法的回退，不需要记录adjustment
  def copy_to_history_version(record_log = true)
    history_basket = Basket::History.new(copy_attrs)
    ActiveRecord::Base.transaction do
      history_basket.save(validate: false)
      copy_basket_stocks_to(history_basket)
      update(latest_history_id: history_basket.id, feed_type: nil)
    end
    BasketAdjustment.log(latest_history, history_basket, original_id) if record_log
  end

  def costomize_title
    "定制的：" + title.to_s
  end

  def original_id
    super ? super : id
  end

  # 下单时取此order_basket_id作为order的basket_id
  def order_basket_id
    latest_history_id
  end

  def is_history?
    false
  end

  def is_costomized?
    false
  end

  # 现在所有的都可以编辑
  # 实盘大赛自动生成的不可以编译
  def can_edit?
    shipan? ? false : true
  end

  def can_drop?
    draft? ? true : false
  end

  # basket状态为完成或审核中，初始化第一天index
  def can_init_first_day_index?
    (completed? || archived?) && !new_record? && basket_indices.blank?
  end

  def newest_version
    self
  end

  # normal的original_id为self
  def original
    if original_id == id
      self
    else
      super
    end
  end

  def follow_by_user(user_id)
    Follow::Basket.create(user_id: user_id, followable: original)
  end

  def unfollow_by_user(user_id)
    original.follows.where(user_id: user_id).destroy_all
  end

  def followed_by_user?(user_id)
    user_id.present? && original.follows.where(user_id: user_id).present?
  end

  # 根据日期找其它对应日期版本的weight是否有人工变化
  def weight_changed?(date)
    history_baskets_by(date).present?
  end

  # 根据日期查找对应版本的weights
  # 定制主题的weight_changed?为false，不会调用到此方法，故没定义
  def stock_weights_by_date(date)
    basket = history_baskets_by(date).last
    basket.stock_ori_weights
  end

  def first_day_stock_weights
    oldest_history = Basket::History.where(original_id: original_id).where("parent_id is null").first
    # FIXME: wangzc
    return {} if oldest_history.blank?
    oldest_history.stock_ori_weights
  end

  # 只取交易时间段的调仓，由于使用的地方已先判断date是否工作日，所以直接用
  def history_baskets_by(date)
    start_time, end_time = trading_time_range(date)
    last_workday = ClosedDay.get_work_day(date - 1)
    last_day_end_time = trading_time_range(last_workday)[1]
    start_time = last_day_end_time if start_on > last_day_end_time && start_on < start_time
    Basket.normal_history.where(original_id: original_id)
      .where("created_at >=? and created_at <= ?", start_time, end_time).order(:id)
  end

  private

  # TODO: delete!
  def history_basket_by(date)
    # 考虑节假日区间
    start_time = ClosedDay.is_workday?(date - 1, market) ? date.to_datetime : ClosedDay.get_work_day(date - 1, market).at_end_of_day
    end_time = (date + 1.day).to_datetime
    Basket.normal_history.where(original_id: original_id).where("created_at >=? and created_at < ?", start_time, end_time).order(:id)
  end

  def copy_attrs
    necessary_attribute_names = attribute_names - %(id type latest_history_id created_at updated_at)
    attributes.slice(*necessary_attribute_names).merge(original_id: original_id, img: img.larger)
  end

  def copy_basket_stocks_to(target_basket)
    basket_stock_attribute_names = %w(stock_id weight notes adjusted_weight created_at updated_at ori_weight real_share)
    copyed_basket_stocks = basket_stocks.map do |bs|
      attrs = bs.attributes.slice(*basket_stock_attribute_names).merge(basket_id: target_basket.id)
      BasketStock.new(attrs)
    end
    BasketStock.import(copyed_basket_stocks, validate: false)
  end
end
