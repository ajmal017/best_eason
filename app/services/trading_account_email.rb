class TradingAccountEmail < TradingAccount 

  validates :broker_no, :uniqueness => { conditions: -> { where(status: STATUS[:normal])} }
  
  validates :broker_no, uniqueness: { scope: :user_id}

  after_create :request_portfolio_and_account

  def bind!
    update(status: STATUS[:normal], actived_date: Date.today) and add_feed(:trading_account)
  end

  # 发送绑定邮件
  def send_active_email
    update(confirmation_token: generate_token(:confirmation_token), confirmation_sent_at: Time.now.utc)

    ::TradingAccountMailer.bind(self.id).deliver
  end

  # 审核不通过
  def unaudited!
    update(confirmation_token: nil, confirmation_sent_at: nil, status: STATUS[:unaudited], audited_date: Date.today)
  end

  def broker_no
    read_attribute(:broker_no).try(:upcase)
  end

  def broker_no=(value)
    write_attribute(:broker_no, value.try(:upcase))
  end

  def self.check_confirmation_token(user_id, token)
    account = find_or_initialize_by(user_id: user_id, confirmation_token: token)

    if account.persisted?
      account.errors.add(:confirmation_token, :expired) unless account.token_period_valid?
    end
    account
  end
  
  def token_period_valid?
    confirmation_sent_at && confirmation_sent_at.utc >= 1.weeks.ago
  end

  def generate_token(column, length=32)
    loop do
      token = SecureRandom.hex(length)
      break token unless self.class.exists?({ column => token })
    end
  end

  def master_account
    self.broker.try(:master_account)
  end
  
  def sub_account
    self.broker_no
  end

  def first_portfolio_message?
    !self.portfolioable
  end

  def premote_reconcile_level
    self.count = self.count.to_i + 1
    self.save!
  end

  def initialize_reconcile_level
    self.send_notification_to_admin("已调平") if self.reconcile_level > 1
    self.update_attributes(count: 0, updated_by: "execDetails")
  end

  def send_notification_to_admin(message = "未能调平")
    Caishuo::Utils::Email.deliver(Setting.trading_notifiers[:emails], "#{Rails.env}环境，用户#{self.user.email}，subAccount=#{self.broker_no}#{message}")
  rescue
    true
  end

  def reconcile_level
    self.count.to_i
  end

  def unreconciled_symbols
    $pms_logger.info("ExecDetails Tws: exec所传来的都已调平，现在检查是否所有symbol均已调平") if Setting.pms_logger
    symbols = []
    self.portfolios.each do |pf|
      symbols << pf.base_stock.split(self) unless pf.reconciled?
    end
    symbols.compact
  end

  def allocate
    self.portfolios.map(&:allocate)
  end

  def corporated_from_position
    Position.account_with(self.id).unallocated.where("shares < ?", 0).select { |p| p.shares + Position.account_with(self.id).stock_with(p.base_stock_id).allocated.sum(:shares) == 0 }
  end
  
  def corporated_to_position
    Position.account_with(self.id).unallocated.select { |p| p.shares > 0 && Position.account_with(self.id).stock_with(p.base_stock_id).allocated.sum(:shares) == 0 }
  end

  def request_portfolio_and_account
    request_portfolio
    request_account_value
    Resque.enqueue_at(1.minutes.from_now, PortfolioRequest, self.id)
  end

  def request_portfolio
    OrderStatusPublisher.publish({"advAccount" => master_account, "subAccount" => sub_account}.to_xml(root: "requestPortfolio"))
  rescue
    true
  end
  
  def request_account_value
    OrderStatusPublisher.publish({"advAccount" => master_account, "subAccount" => sub_account}.to_xml(root: "requestAccountValues"))
  rescue
    true
  end

  def self.request_execution
    self.all.map(&:request_execution)
  end
  
  def request_execution
    OrderStatusPublisher.publish({"advAccount" => master_account, "subAccount" => sub_account}.to_xml(root: "requestExecutions"))
    send_notification_to_admin if reconcile_level >= 2
  end

  def category_name
    "美股港股账号"
  end

end
