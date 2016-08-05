# 股票复权信息
class StockAdjustingFactor < ActiveRecord::Base
  def adjust!
    return if adjusted? || Date.today < ex_divi_date || ex_divi_date < Date.parse("2014-01-01")

    adjust_followed_prices
    adjust_position_archives

    set_adjusted
  end

  def adjust_followed_prices
    Follow::Stock.where(followable_id: base_stock_id).each do |follow|
      next if follow.created_at.to_date > ex_divi_date || follow.price.blank?
      follow.update(price: (follow.price * price_ratio).round(2))
    end
  end

  def adjust_position_archives
    PositionArchive.stock_with(base_stock_id).where("archive_date < ?", ex_divi_date).find_each do |pa|
      adjusted_shares = (pa.adjusted_shares || pa.shares) * shares_ratio
      pa.update(adjusted_shares: adjusted_shares)
    end
  end

  # 价格复权使用
  def price_ratio
    prev_ratio / ratio_adjusting_factor
  end

  # 股数复权使用
  def shares_ratio
    accu_bonus_share_ratio / (prev_log.try(:accu_bonus_share_ratio) || 1.0)
  end

  def prev_ratio
    prev_log.try(:ratio_adjusting_factor) || 1.0
  end

  def prev_log
    @prev_log ||= self.class.where(base_stock_id: base_stock_id).where("ex_divi_date < ?", ex_divi_date).order(ex_divi_date: :desc).first
  end

  private

  def set_adjusted
    $redis.set(adjust_key, true, ex: 1.day)
  end

  def adjusted?
    $redis.get(adjust_key).present?
  end

  def adjust_key
    "CS:StockAdjustingFactor:#{base_stock_id}:#{ex_divi_date.to_s(:db)}"
  end
end
