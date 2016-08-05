class BasketStock < ActiveRecord::Base
  belongs_to :basket
  belongs_to :stock, class_name: 'BaseStock', foreign_key: 'stock_id'

  validates :stock_id, uniqueness: {scope: :basket_id}
  validates :weight, presence: true
  validates :notes, sensitive: {show_words: true}

  before_save :set_adjusted_weight, :set_ori_weight

  delegate :market_area, :symbol, :com_name, :realtime_price, :change_percent, :one_year_return, :currency_unit, to: :stock

  alias :basket_stock_id :id


  def weight_percent
    (self.weight * BigDecimal.new(100)).round(1) rescue 0
  end

  # for 创建basket attrs
  def basic_infos
    as_json(only: [:stock_id, :weight], methods: [:basket_stock_id]).merge(stock.basic_infos)
  end

  private

  def set_adjusted_weight
    if self.weight_changed? || self.adjusted_weight.blank?
      self.adjusted_weight = self.weight
    end
  end

  def set_ori_weight
    self.ori_weight = self.weight if self.ori_weight.blank? || self.basket.draft?
  end
end
