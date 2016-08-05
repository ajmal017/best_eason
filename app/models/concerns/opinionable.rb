module Opinionable 
  extend ActiveSupport::Concern
  
  included do
    
    has_many :opinions, as: :opinionable, class_name: :Opinion, dependent: :destroy
    has_many :opinioners, through: :opinions, source: :user
  end

  # 看涨看跌比例
  def set_bullish_percent
    bullished_count = Opinion.one_month_bullish_count(self)
    bearished_count = Opinion.one_month_bearish_count(self).to_f
    total_count = bullished_count + bearished_count
    bullish_percent = total_count.zero? ? 0 : (bullished_count * 100 / total_count rescue 0)
    bearish_percent = total_count.zero? ? 0 : (bearished_count * 100 / total_count rescue 0)
    update(bullish_percent: bullish_percent, bearish_percent: bearish_percent)
  end

  def opinions_datas
    as_json(only: [:bullish_percent, :bearish_percent]).transform_values(&:round)
  end
end
