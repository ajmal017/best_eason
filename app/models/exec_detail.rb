class ExecDetail < ActiveRecord::Base
  scope :processed, -> { where(processed: true) }
  scope :ib_order_id_with, -> (ib_order_id) { where(ib_order_id: ib_order_id) }
  scope :time_with, -> (time) { where(time: time) }
  scope :by_ib_id, -> (ib_id) { where(contract_id: ib_id) }
  scope :unprocessed, -> { where.not(processed: true) }
  scope :selled, -> { where(side: "SLD") }
  scope :buyed, -> { where(side: "BOT") }
  scope :time_lte, -> (end_time) { where("time <= ?", end_time) }
  scope :time_between, -> (begin_time, end_time) { where("time >= ? and time <= ?", begin_time.strftime("%Y%m%d %H%M%S"), end_time.strftime("%Y%m%d %H%M%S")) }
  scope :account_with, ->(trading_account_id) { where(trading_account_id: trading_account_id) }
  scope :by_stock, ->(stock_id) { where(stock_id: stock_id) }

  belongs_to :stock, class_name: 'BaseStock', foreign_key: 'stock_id'
  
  def process!
    self.update(processed: true)
  end
  
  def sell?
    side == "SLD"
  end

  def trading_flag
    sell? ? -1 : 1
  end
end
