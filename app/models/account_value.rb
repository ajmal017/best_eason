class AccountValue < ActiveRecord::Base
  # 货币种类
  UNITS = {usd: 'USD', hkd: 'HKD', base: 'BASE', cny: 'CNY'}

  # 类型
  TYPES = { 
    buying_power: "BuyingPower", 
    total_cash_balance: "TotalCashBalance", 
    total_cash_value: "TotalCashValue",
    last_total_cash: "LastTotalCash",
    net_liquidation: "NetLiquidation", 
    net_liquidation_by_currency: "NetLiquidationByCurrency",
    initial_capital: 'InitialCapital',
    original_cash: 'OriginalCash',
    last_asset: "AssetBalance",
    frozen_cash: "FrozenCash"
  }
  
  CASH_KEYS = ["TotalCashBalance", "TotalCashValue"]

  belongs_to :user

  belongs_to :trading_account

  scope :by_user, -> (user_id) { where(user_id: user_id) }
  scope :key_with, -> (type) { where(key: type) }
  scope :currency_with, -> (currency) { where(currency: currency) }
  scope :of_buying_power, -> { where(key: TYPES[:buying_power]) }
  scope :of_cash_balance, -> { where(key: TYPES[:total_cash_balance]) }
  scope :last_total_cash, -> { where(key: TYPES[:last_total_cash]) }   #可用现金
  scope :original_cash, -> { where(key: TYPES[:original_cash]) }
  scope :last_asset, -> { where(key: TYPES[:last_asset]) }
  scope :frozen_cash, ->{ where(key: TYPES[:frozen_cash]) } #冻结
  scope :usable_and_frozen, ->{ where(key: [TYPES[:frozen_cash], TYPES[:last_total_cash]]) }
  scope :of_net_liquidation, -> { where(key: TYPES[:net_liquidation]) }
  scope :of_net_liquidation_by_currency, -> { where(key: TYPES[:net_liquidation_by_currency]) }
  scope :by_type, -> (type){ where(key: TYPES[type.to_sym])}
  scope :account_with, -> (account_id) { where(trading_account_id: account_id) }

  def value
    read_attribute(:value).to_f
  end

  # 用户所有现金
  def self.total_cash(user_id)
    account_ids = where(user_id: user_id).select("distinct(trading_account_id)").map(&:trading_account_id)
    currencies = TradingAccount.where(id: account_ids).binded.map{|account| [account.id, account.base_currency]}.to_h
    
    where(trading_account_id: currencies.keys).last_total_cash.map do |account|
      currency = account.currency == "BASE" ? currencies[account.trading_account_id] : account.currency
      account.value * Currency.transform(currency, 'USD')
    end.sum.to_f
  end

  # 所有现金,目前主要用于用于平均换手率
  def self.whole_cash
    currencies = TradingAccount.active.select("id, base_currency").map{|x|[x.id, x.base_currency]}.to_h

    last_total_cash.inject(0) do |sum, account_value|
      currency = account_value.currency == "BASE" ? currencies[account_value.trading_account_id] : account_value.currency
      sum + account_value.value * Currency.transform(currency, 'USD')
    end
  end
end
