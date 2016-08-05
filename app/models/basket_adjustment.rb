class BasketAdjustment < ActiveRecord::Base
  STATES = {
    normal: 0, # 交易时间段正常调仓
    pending: 1, # 非交易时段调仓、待成交
    opening_adjust: 2,  # 开市矫正盘后-盘前的调仓
    cancel: 4, #取消，系统开始检测不合法时回退并取消调仓
    hide: 5 #隐藏
  }

  STATES_DESC = {
    1 => "待成交", 4 => "交易失败"
  }

  scope :sort_by_time, -> { order("created_at desc") }
  scope :opening_adjust, -> { where(state: STATES[:opening_adjust]) }
  scope :pending, -> { where(state: STATES[:pending]) }
  scope :visible, -> { where.not(state: STATES[:hide]) }
  # 可计算holding_pnl的，只有0、2状态可计算pnl
  scope :calculable, -> { where(state: [0, 2]) }

  validates :next_basket_id, :original_basket_id, presence: true

  has_many :basket_adjust_logs, -> { where.not(action: 5).order("field(action , '1', '4', '2', '3') desc, created_at desc") }, dependent: :destroy
  has_many :basket_stock_snapshots, dependent: :destroy
  belongs_to :prev_basket, class_name: 'Basket', foreign_key: :prev_basket_id
  belongs_to :next_basket, class_name: 'Basket', foreign_key: :next_basket_id
  belongs_to :original_basket, class_name: 'Basket', foreign_key: :original_basket_id
  
  before_create :set_date

  after_commit :send_notification, on: :create, if: -> { [0, 1, 2].include?(self.state) }

  def send_notification
    Resque.enqueue(SendPositionNotificationWorker, self.original_basket.original_id, self.id)
  end

  def basket_adjust_logs_desc
    adjust_logs = basket_adjust_logs
    adjust_logs.select{|x| x.stock_id.present? } + adjust_logs.select{|x| x.stock_id.blank? }
  end
  # adjust_logs 先按操作类型排序：新增、删除、加仓、减仓，再按股票比重排序
  # 前台展示时需要另外处理把现金排到最后
  def self.logs(original_basket_id)
    BasketAdjustment.visible.where(original_basket_id: original_basket_id).includes(:basket_adjust_logs)
                    .where("basket_adjust_logs.action <> ?", BasketAdjustLog::ACTIONS[:system])
                    .order("basket_adjustments.id desc")
                    .order("basket_adjust_logs.action, basket_adjust_logs.weight_to desc").limit(10)
  end

  def self.log(prev_basket, next_basket, original_basket_id)
    state = next_basket.created_in_trading? ? STATES[:normal] : STATES[:pending]
    basket_adjustment = self.create({state: state, prev_basket_id: prev_basket.try(:id), next_basket_id: next_basket.id, original_basket_id: original_basket_id})
    BasketStockSnapshot.set_snapshot(basket_adjustment.id, prev_basket, next_basket)
    Resque.enqueue(BasketAdjustLogsGenerator, basket_adjustment.id)
  end

  def generate_logs
    return "不能再次生成" unless basket_adjust_logs.blank? && can_regenerate_logs?

    prev_basket_stock_infos = prev_basket_stock_snapshots
    next_basket_stock_weights = self.next_basket.stock_ori_weights
    stock_ids = (prev_basket_stock_infos.keys + next_basket_stock_weights.keys).uniq

    destroy_logs
    logs = BaseStock.where(id: stock_ids).map do |stock|
      BasketAdjustLog.generate(self, stock, prev_basket_stock_infos[stock.id], next_basket_stock_weights[stock.id])
    end
    # cash log: stock_id nil
    logs << BasketAdjustLog.generate(self, nil, prev_cash_infos(prev_basket_stock_infos), next_basket_stock_weights[Stock::Cash.id])

    BasketAdjustLog.import(logs, validate: true)
  end

  def prev_basket_stock_snapshots
    return {} if prev_basket.blank?  # 刚创建时，没有prev_basket

    stock_infos = self.basket_stock_snapshots.by_prev_basket(self.prev_basket_id).map do |bss|
      [bss.stock_id, bss.attributes.slice("weight", "stock_price", "change_percent")]
    end.to_h
    realtime_weights = prev_realtime_weights(stock_infos)
    stock_infos.map do |stock_id, infos|
      [stock_id, infos.merge(realtime_weight: realtime_weights[stock_id]).symbolize_keys]
    end.to_h
  end

  def destroy_logs
    self.basket_adjust_logs.delete_all
  end

  def opening_adjust?
    state == STATES[:opening_adjust]
  end

  def pending?
    state == STATES[:pending]
  end

  # 暂时只显示2个状态的描述，其他页面不需要显示
  def state_desc
    STATES_DESC[state]
  end
  
  private

  def set_date
    self.date = Date.today
  end

  def prev_cash_infos(prev_basket_stock_infos)
    cash_weight = 1 - (prev_basket_stock_infos.values.map{|h| h[:weight]}.reduce(:+) || 0)
    {weight: cash_weight, stock_price: 1}
  end

  def prev_realtime_weights(prev_basket_stock_infos)
    weights = prev_basket_stock_infos.map{|stock_id, info| [stock_id, info["weight"]]}.to_h
    weights_with_cash = weights.present? ? Stock::Cash.id_weights_with(weights) : {}
    rets = prev_basket_stock_infos.map{|stock_id, info| [stock_id, info["change_percent"]]}.to_h
    BasketIndex::RealtimeWeight.adjust_by(weights_with_cash, rets)
  end

  def can_regenerate_logs?
    !opening_adjust?
  end

end
