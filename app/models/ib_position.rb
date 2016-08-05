class IbPosition < ActiveRecord::Base
  validates :user_id, presence: true
  validates :base_stock_id, presence: true
  validates :base_stock_id, :uniqueness => { :scope => :trading_account_id }

  belongs_to :user
  belongs_to :trading_account
  
  after_save :request_portfolio
  before_validation :copy_attrs

  private
  def request_portfolio
    trading_account.request_portfolio if self.position_changed?
  end

  def copy_attrs
    self.user_id = self.trading_account.user_id
  end
end
