class TwsExec < ExecDetail
  scope :by_user, -> (user_id) { where(user_id: user_id) }
  scope :account_with, ->(account_id) { where(trading_account_id: account_id) }
  scope :instance_with, -> (instance_id) { where(instance_id: instance_id) unless instance_id.nil? }
  scope :stock_with, -> (stock_id) { where(stock_id: stock_id) unless stock_id.nil? }
  scope :time_range, -> (start_time, end_time) { where("time >= ? and time <= ?", start_time, end_time) }
  scope :category_with, ->(opts) { instance_with(opts[:instance_id]).stock_with(opts[:stock_id])}
  scope :profited, -> { where.not(currency: nil) }

  alias_attribute :base_stock_id, :stock_id

  def reconcile!(user_id)
    @account_id = user_id
    others_position.tws_reconcile!(shares.to_i, avg_price.to_f, side)
    process!
  end

  def others_position
    @others ||= Position.find_or_create_by(instance_id: 'others', base_stock_id: stock.id, trading_account_id: @account_id)
  end

  def stock
    @stock ||= BaseStock.find_by(ib_id: contract_id)
    return @stock if @stock
    @stock = BaseStock.find_by(ib_symbol: symbol)
    $pms_logger.warn('IB_ID 变更 #{@stock.ib_id} => #{contract_id}')
    @stock
  end

  def trading_flag
    side == 'SLD' ? -1 : 1
  end

  def realtime_price
    $redis.hget(snapshot_key, "last").to_d rescue 0
  end

  def snapshot_key
    "realtime:" + stock_id.to_s
  end

  def self.test_retry
    ActiveRecord::Base.transaction do
      TwsExec.create(shares: 1)
      sleep(30)
      TwsExec.last
      TwsExec.create(shares: 1)
    end
  end

  # 投资概览使用
  def exec_cost
    shares.to_i.abs * avg_price
  end

  def exec_profit
    (realtime_price - avg_price) * shares.to_i * trading_flag
  end
end
