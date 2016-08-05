class UserBinding < ActiveRecord::Base

  include PrettyIdable
  
  validates :user_id, presence: true, uniqueness: true

  validates :broker_id, presence: true, :uniqueness => { :scope => :broker_user_id }

  belongs_to :user
  
  belongs_to :broker

  has_many :user_brokers, foreign_key: :user_id, primary_key: :user_id, dependent: :delete_all
  
  has_one :reconcile_request_list, foreign_key: :broker_user_id, primary_key: :broker_user_id

  scope :by_broker_user_id, -> (borker_user) { where(broker_user_id: borker_user) }
  
  after_create :request_portfolio_and_account

  def self.check_by_user_id(user_id)
    UserBinding.where(user_id: user_id, available: true).exists?
  end
  
  def get_binding_user
    raise ::Trading::BindingUserError.new if self.user.nil?
    self.user
  end
  
  def first_portfolio_message?
    !self.portfolioable
  end
  
  def set_unavailable
    self.update_attributes(available: false)
  end

  def unlock_user
    self.update_attributes(available: true)
  end
  
  def promote_reconcile_level
    self.count = self.count + 1
    self.updated_by = "execDetails"
    self.save!
  end
  
  def initialize_reconcile_level
    self.send_notification_to_admin("已调平") if self.reconcile_level > 1
    self.update_attributes(count: 0, updated_by: "execDetails")
  end
  
  def udpate_base_currency(base_currency)
    self.update_attributes(base_currency: base_currency, updated_by: "accoutValue")
  end

  def self.sub_account(user_id)
    self.find_by(user_id: user_id).try(:sub_account)
  end
  
  def self.master_account(user_id)
    self.find_by(user_id: user_id).try(:master_account)
  end
  
  def master_account
    self.broker.try(:master_account)
  end
  
  def sub_account
    self.broker_user_id
  end
  
  def reconcile
    self.user.reconcile
    self.update_attributes(available: true, count: 0, updated_by: "execDetails")
  end
  
  def self.request_execution
    self.all.map(&:request_execution)
  end
  
  def request_execution
    OrderStatusPublisher.publish({"advAccount" => master_account, "subAccount" => sub_account}.to_xml(root: "requestExecutions"))
    send_notification_to_admin if reconcile_level >= 2
  end

  def send_notification_to_admin(message = "未能调平")
    Caishuo::Utils::Email.deliver(Setting.trading_notifiers[:emails], "#{Rails.env}环境，用户#{self.user.email}，subAccount=#{self.broker_user_id}#{message}")
  rescue
    true
  end

  def reconcile_level
    self.count.to_i
  end
  
  def reconcile_by_symbol_and_price(symbol, avg_price)
    portfolio = Portfolio.by_user(user_id).joins(:base_stock).where("base_stocks.symbol = ? or base_stocks.ib_symbol = ?", symbol, symbol).first
    portfolio.reconcile(avg_price) if portfolio
    symbols = self.reconcile_request_list.symbol.split(",").delete_if { |x| x == symbol }.join(",")
    self.update!(available: true, count: 0) if symbols.blank?
    self.reconcile_request_list.update_attributes(symbol: symbols)
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
    
  def broker_user_id
    read_attribute(:broker_user_id).try(:upcase)
  end

  def broker_user_id=(value)
    write_attribute(:broker_user_id, value.try(:upcase))    
  end

  # 判断user_id是否有权限查看该账号
  def can?(user_id)
    user_id == user_id
  end

  # TODO 待定，要确认一下
  def unbind
    destroy
  end

  private
end
