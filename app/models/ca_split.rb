class CaSplit < ActiveRecord::Base
  scope :by_date, -> (date) { where(date: date) }
  scope :not_finished, -> { where(finished: false) }
  scope :by_stock, -> (stock) { where("base_stock_id = ? or symbol = ?", stock.id, stock.ib_symbol) }
  scope :date_between, -> (start_date, end_date) { where("date >= ? and date <= ?", start_date, end_date) }
  
  def finished!
    self.finished = true
    self.save!
    $pms_logger.info("UpdatePortfolio: 设置已处理过split,symbol=#{symbol}") if Setting.pms_logger
  end
  
  def before_split
    factor.split(":")[0].to_f
  end
  
  def after_split
    factor.split(":")[1].to_f
  end
  
  def self.can_split?(stock)
    self.date_between(_30_days_ago, _30_days_from_now).by_stock(stock).lock(true).first
  end
  
  def self._30_days_ago
    30.days.ago.in_time_zone('Eastern Time (US & Canada)').to_date
  end
  
  def self._30_days_from_now
    30.days.from_now.in_time_zone('Eastern Time (US & Canada)').to_date
  end
end
