class Admin::HongbaosController < Admin::ApplicationController
  def index
    @page_title = '到期红包列表'
    trading_accounts = TradingAccount.arel_table
    @trading_accounts = TradingAccount.includes(:user).select(:user_id, 'min(trading_since) trading_since').where(trading_accounts[:trading_since].lteq(30.days.ago.to_date)).group(:user_id).order(trading_since: :desc)
  end
end
