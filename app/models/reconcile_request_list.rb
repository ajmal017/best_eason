class ReconcileRequestList < ActiveRecord::Base
  validates :trading_account_id, presence: true, uniqueness: true
  
  belongs_to :user
  belongs_to :trading_account
  
  scope :order_by_id, -> { order("id desc") }

  before_create :set_user
  
  def user_binding
    # UserBinding.find_by(broker_user_id: self.broker_user_id)
    TradingAccount.find_by(broker_no: self.broker_user_id)
  end
  
  def can_publish?
    (Time.now - self.created_at >= reconcile_delay_seconds)
  end
  
  def reconcile_delay_seconds
    Setting.reconcile_delay.to_i * 60
  end
  
  def unreconciled
    res = []
    self.symbol.split(",").each do |s|
      stock_id = BaseStock.by_symbol(s).first.try(:id)
      res << [s, portoflio_position(stock_id), position_shares(stock_id)] 
    end
    res
  end
  
  def portoflio_position(stock_id)
    Portfolio.by_user(user_id).stock_with(stock_id).first.position
  end
  
  def position_shares(stock_id)
    Position.by_user(user_id).stock_id_with(stock_id).sum(:shares).to_f
  end
  
  def update_broker_user_id_and_symbol(account_name, ib_symbol, updated_by)
    self.with_lock do
      self.broker_user_id = account_name
      if self.symbol.blank?
        self.symbol = ib_symbol 
      elsif !self.symbol.include?(ib_symbol)
        self.symbol = self.symbol + "," + ib_symbol
      end
      self.updated_by = updated_by
      self.save!
    end
  end
  
  def unreconciled_symbols
    symbols = []
    self.user.portfolios.each do |pf|
      symbols << pf.base_stock.split(user) unless pf.reconciled?
    end
    symbols.compact
  end

  before_create :set_user
  def set_user 
    self.user_id = self.trading_account.user_id
  end
end
