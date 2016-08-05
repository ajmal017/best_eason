class Broker < ActiveRecord::Base
  validates :master_account, presence: true

  STATUS_PUBLIC = 'published'
  STATUS_NEW = 'new'
  STATUS_SIM = "simulated"
  STATUS_P2P = "p2p"
  STATUSES = [STATUS_NEW, STATUS_PUBLIC, STATUS_SIM, STATUS_P2P]

  # include_simulated 是否包含模拟账户
  scope :published, ->(include_simulated = false) { include_simulated ? where(status: [STATUS_PUBLIC, STATUS_SIM]) : where(status: STATUS_PUBLIC) }
  scope :by_market, -> (market) { market.present? ? where("market like ?", "%#{market}%") : all }
  scope :displayed, -> { where(display: true) }
  scope :asc_position, -> { order(position: :asc) }
  scope :p2p_broker, -> { find_by(master_account: Setting.trading_account.p2p) }

  BIND_TYPES = {
    unicorn: :email,
    ib: :email,
    citics: :password,
    icitics: :password
  }
  MARKET_AREA_NAMES = {:cn => "沪深", :us => "美股", :hk => "港股"}

  enum trading_status: [:active, :cleaning_order, :syncing_position, :syncing_cash]

  # 绑定方式
  # 目前两种方式
  # email: 发送确认邮件到开户Email, 此种方式产生TradingAccount记录
  # password: 直接输入资金账号、密码，调用券商接口确认, 此种方式不产生TradingAccount记录
  def bind_type
    BIND_TYPES[name.to_sym]
  end

  # safety_info 通信密码
  def bind(user, attrs={})
    case market
    when "cn"
      attrs.to_h.symbolize_keys!
      result_account = RestClient.trading.account.bind(self.id, user.id, attrs[:broker_no], attrs[:password], attrs[:safety_info])
      result_account.add_feed(:trading_account) if result_account.errors.blank?
      result_account
    else
      TradingAccountEmail.create(attrs.merge(user_id: user.id, status: TradingAccountEmail::STATUS[:new], broker_id: self.id))
    end
  end

  def market_cn?
    market == "cn"
  end

  def logo_url(version=nil)
    logo[version||:small]
  end

  def logo
    @logo ||= { 
      mini:  "#{asset_host}/images/v3/trader/#{name}_20.png",
      small: "#{asset_host}/images/mobile/brokers/#{name}_50.png", 
      large: "#{asset_host}/images/mobile/brokers/#{name}_220.png"
    }
  end

  # 手机券商绑定url
  def mobile_bind_url
    return nil unless market_cn?

    "#{Setting.host}/mobile/shares/brokers/#{self.id}/accounts/new"
  end

  def need_communication_password?
    return false unless market_cn?

    ['东方证券', '东海证券', '东吴证券', '海通证券', '西部证券'].include?(self.cname)
  end

  # 0 不需要验证 1 只需要密码 2 密码和通讯密码
  def need_password_type
    return 0 unless market_cn?
    need_communication_password? ? 2 : 1
  end

  private
  def asset_host
    @@asset_host ||= Caishuo::Application.config.action_controller.asset_host.call("/images") rescue ""
  end

end
