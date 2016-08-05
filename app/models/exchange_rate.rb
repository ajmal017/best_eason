class ExchangeRate < ActiveRecord::Base
  validates :currency, uniqueness: {scope: :account_name}
  validates :account_name, uniqueness: {scope: :currency}

  belongs_to :trading_account

  before_create :set_user

  private
  def set_user
    self.user_id = self.trading_account.user_id
  end
end
