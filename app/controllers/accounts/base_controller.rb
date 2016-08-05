class Accounts::BaseController < ApplicationController
  before_filter :authenticate_user!
  before_action :set_menu
  
  private
  def set_menu
    @top_menu_tab = 'users'
  end

  def load_trading_account
    @trading_account = TradingAccount.find_with_pretty_id(current_user.id, params[:account_id])
    @trading_account = current_user.binded_accounts.first if @trading_account.blank?
    raise ActiveRecord::RecordNotFound if @trading_account.blank?
  end
end
