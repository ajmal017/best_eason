class TradingAccountPT < TradingAccountPassword
  attr_accessor :admin
  validates :broker_no, uniqueness: true
  alias_attribute :pt_status, :extend_status

  PT_STATUS_NAMES = ['正常', '异常', '销户', '结束', 'SellOnly', 'BuyOnly', 'Locked']

  before_destroy do
    unless admin
      self.errors.add :broker_no, 'PT账号不能解绑'
      false
    end
  end

  def extend_status_name
    PT_STATUS_NAMES[extend_status] if extend_status
  end

  def normal?
    pt_status == 0
  end

  def buy_only?
    pt_status == 5
  end

  def can_not_buy?
    [0, 5].exclude? pt_status
  end

  def sell_only?
    pt_status == 4
  end

  def pt?
    true
  end

  def can_not_sell?
    [0, 4].exclude? pt_status
  end

  def out?
    [2, 3, 6].include? pt_status
  end

  # todo
  def liquidated?
    [2, 6].include? pt_status
  end

  def cancelable?
    false
  end

  def initial_capital
    @initial_capital ||= AccountValue.by_user(user_id).account_with(id).original_cash.first.try(:value) || 0
  end

  def total_profit
    total_property-initial_capital
  end

  def total_profit_percent
    return 0 if initial_capital.zero?
    ((total_property-initial_capital)*100/initial_capital).round(2)
  end
end
