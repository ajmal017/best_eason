class BasketStockSnapshot < ActiveRecord::Base
  validates :basket_id, :stock_id, presence: true

  belongs_to :basket_adjustment
  belongs_to :basket
  belongs_to :stock, class_name: 'BaseStock', foreign_key: :stock_id

  scope :by_prev_basket, ->(basket_id) { where(basket_id: basket_id) }

  def self.set_snapshot(basket_adjustment_id, basket, next_basket)
    return if basket.blank?
    copy_attrs = ["basket_id", "stock_id", "weight", "notes", "adjusted_weight", "ori_weight"]
    added_params = {basket_adjustment_id: basket_adjustment_id, next_basket_id: next_basket.id}
    basket_stocks = basket_stocks_by(basket, next_basket)

    snapshots = basket_stocks.map do |bs|
      stock_info = {stock_price: bs.stock.realtime_price, change_percent: bs.stock.change_ratio}
      snapshot_params = bs.attributes.slice(*copy_attrs).merge(added_params).merge(stock_info)
      self.new(snapshot_params)
    end
    self.import(snapshots)
  end

  private

  # 取prev_basket的basket_stocks，及next_basket中prev不存在的
  def self.basket_stocks_by(prev_basket, next_basket)
    basket_stocks = prev_basket.basket_stocks
    next_stocks = next_basket.basket_stocks.where.not(stock_id: basket_stocks.map(&:stock_id)).where("weight>0")
    basket_stocks + next_stocks
  end
end