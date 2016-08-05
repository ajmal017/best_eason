class BasketWeightLog < ActiveRecord::Base
  validates_presence_of :stock_id, :basket_id, :adjusted_weight, :date
  validates :date, uniqueness: {scope: [:stock_id, :basket_id]}

  def self.stock_adjusted_weights(basket_id, date)
    logs = self.where(:basket_id => basket_id, :date => date)
    weights = logs.map{|x|[x.stock_id, x.adjusted_weight]}.to_h
    weights.present? ? Stock::Cash.id_weights_with(weights) : {}
  end

  def self.recreate_logs(stock_weights_hash, basket_id, date)
    self.where(:basket_id => basket_id, :date => date).delete_all
    logs = stock_weights_hash.select{|id,w| id>0}.map do |stock_id, weight|
      self.new ({:stock_id => stock_id, :basket_id => basket_id, :adjusted_weight => weight, :date => date})
    end
    self.import(logs, validate: false)
  end
end