class Ajax::AccountsController < Ajax::ApplicationController
  skip_before_action :require_xhr?, only: [:save_avatar, :crop_avatar, :setting_crop]

  before_filter :authenticate_user!

  before_action :load_trading_account, only: [:equities, :incomes]

  # 账户净值表现
  def equities
    datas = UserDayProperty.datas_by(@trading_account, (Date.parse(params[:date]) rescue nil))
    render json: {unit: @trading_account.cash_unit, datas: datas}
  end

  # 收益表现
  def incomes
    begin_date = Date.parse(params[:date]) rescue nil
    datas = UserProfit.datas_by(@trading_account, begin_date || '2014-10-10')
    render json: {unit: @trading_account.cash_unit, datas: datas}
  end

  private

  def load_trading_account
    @trading_account = TradingAccount.find_with_pretty_id(@current_user.id, params[:id])
  end
  
end
