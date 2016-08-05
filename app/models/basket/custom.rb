class Basket::Custom < Basket
  skip_callback :save, :before, :set_other_attrs
  before_create :copy_avatar_from_parent

  # basket_stock_weights，定制页面
  def self.create_from(user_id, custom_from_basket, basket_stock_weights_attrs)
    ActiveRecord::Base.transaction do
      basket = copy_from(user_id, custom_from_basket)
      basket.update(basket_stock_weights_attrs)
      basket.convert_other_same_original_custom_baskets_to_history
      basket
    end
  end

  # 减少sql时间，目前持仓调整定制用
  # stock_count_hash:  {1: 100, 33: 200};
  def self.custom_from(user_id, custom_from_basket, stock_count_hash)
    ActiveRecord::Base.transaction do
      basket = copy_from(user_id, custom_from_basket)
      basket_stocks = convert_to_basket_stocks(basket.id, stock_count_hash, custom_from_basket.stock_notes)
      BasketStock.import(basket_stocks, validate: false)
      basket.convert_other_same_original_custom_baskets_to_history
      basket
    end
  end

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

  def convert_other_same_original_custom_baskets_to_history
    Basket::Custom.where(original_id: self.original_id, author_id: self.author_id).where.not(id: self.id).update_all(type: 'Basket::CustomHistory')
  end

  # 定制的主题，每次定制都生成新的，而且单独计算指数，所以无变化
  def weight_changed?(date)
    false
  end

  # blank
  def history_baskets_by(date)
    []
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

  private
  def self.copy_from(user_id, basket)
    copy_param_names = %w(description category state third_party market)
    copy_params = basket.attributes.slice(*copy_param_names)
    copy_params.merge!({title: basket.costomize_title, original_id: basket.original_id, author_id: user_id, 
                        visible: false, parent_id: basket.id, start_on: Time.now, modified_at: Time.now})
    create(copy_params)
  end

  def copy_avatar_from_parent
    self.img = self.parent.img.larger
    self.write_img_identifier
  end

  def self.convert_to_basket_stocks(basket_id, id_count_hash, stock_notes_hash)
    stocks = BaseStock.where(id: id_count_hash.keys)
    total_money = stocks.map{|s| s.realtime_price * id_count_hash[s.id]}.sum
    total_weight_left = BigDecimal.new(1)
    basket_stocks = []
    stocks.each_with_index do |stock, index|
      cal_weight = stock.realtime_price * id_count_hash[stock.id] / total_money
      total_weight_left = total_weight_left - cal_weight
      weight = index == (stocks.size-1) ? total_weight_left + cal_weight : cal_weight
      basket_stock_params = {basket_id: basket_id, stock_id: stock.id, weight: weight, adjusted_weight: weight, ori_weight: weight, created_at: Time.now, updated_at: Time.now, notes: stock_notes_hash[stock.id]}
      basket_stocks << BasketStock.new(basket_stock_params)
    end
    basket_stocks
  end
end