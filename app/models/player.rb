class Player < ActiveRecord::Base
  STATUS_NAMES = ['正常', '出局']
  enum status: [:normal ,:out]

  attr_accessor :broker_no
  # has_many :account_values, foreign_key: :trading_account_id
  belongs_to :contest
  belongs_to :trading_account
  belongs_to :user

  scope :normal, -> { where(status: statuses[:normal]) }
  scope :by_user, ->(user_id) { where(user_id: user_id) }
  scope :by_contest, ->(contest_id) { where(contest_id: contest_id) }
 
  validates :user, presence: true
  validates :contest, presence: true

  after_create :create_blank_basket
  after_save :destroy_old_trading_account, if: :trading_account_id_changed?
  after_destroy :destroy_relations
  after_save :set_original_cash, if: :original_money_changed?
  before_save :update_account, if: :broker_no

  def set_original_cash
    original_cash_obj.update(value: original_money)
  end

  def self.status_options
    statuses.map{|k,v| [k, STATUS_NAMES[v]] }
  end

  def pt_data_error?
    property_change_percent.abs > 0.11
  end

  def property_change_percent
    beginning_property = histroical_property ? histroical_property : original_cash
    (trading_account.total_property-beginning_property)/beginning_property
  end

  def histroical_property
    UserDayProperty.where(trading_account_id: trading_account_id).where(date: 1.day.ago.to_date.to_s(:db)).first.try(:total)
  end

  def unaudite_account
    trading_account.update(status: TradingAccount::STATUS[:unaudited])
  end

  def update_account
    pt_account = TradingAccountPT.find_or_initialize_by(user_id: user_id, broker_no: broker_no, broker_id: contest.broker_id, status: 1, cash_id: contest.broker.master_account+'_'+broker_no, base_currency: 'CNY')
    pt_account.last_login_at = Time.now.end_of_year
    self.trading_account = pt_account
  end

  def self.create_by_import(user_id, contest_id, broker_no)
    player = find_or_initialize_by(user_id: user_id, contest_id: contest_id)
    player.broker_no = broker_no
    player.update_account
    flag = false
    flag = player.trading_account.save && player.save
    Resque.enqueue(PTLoginWorker, player.trading_account_id) if flag
    [flag, player]
  end

  def account_values
    AccountValue.where(trading_account_id: trading_account_id)
  end

  def original_cash_obj
    account_values.original_cash.first_or_initialize
  end

  def original_cash
    original_cash_obj.value
  end

  def useable_money
    account_values.last_total_cash.first.try(:value)
  end

  def asset
    account_values.last_asset.first.try(:value)
  end

  def force_change_original_money(money)
    return false unless money.to_i > 0

    original_cash = account_values.original_cash.last
    original_cash.update(value: money)
    self.update(original_money: money)
  end

  private

  def destroy_old_trading_account
    ta = TradingAccount.find_by(id: trading_account_id_was)
    ta.assign_attributes(admin: true).try(:destroy) if ta
  end

  def create_blank_basket
    AdjustBasketByOrder.create_contest_basket(self.user, self.trading_account_id)
  end

  def destroy_relations
    trading_account.assign_attributes(admin: true)
    trading_account.destroy
    basket_rank = contest.basket_rank_of(user_id)
    basket_rank.basket.update_attribute(:state, Basket::STATE[:blocked]) if basket_rank.try(:basket)
    basket_rank.try(:destroy)
  end
end
