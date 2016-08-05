class HistoricalQuoteResync < ActiveRecord::Base
  
  scope :by_base_stock_id, -> (base_id) { where(base_stock_id: base_id) }
  scope :not_kline, -> { where(kline: false) }

end
