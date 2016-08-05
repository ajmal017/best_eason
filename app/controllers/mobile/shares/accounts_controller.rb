class Mobile::Shares::AccountsController < Mobile::ApplicationController
  layout false
  before_action :load_broker, only: [:create, :new]

  def new
  end

  def create
    @trading_account = TradingAccount.bind(@current_user, @broker, account_params) if @current_user
  end

  private

  def load_broker
    @broker = Broker.find(params[:broker_id])
  end

  def account_params
    params.require(:trading_account).permit(:broker_no, :password, :safety_info)
  end
end
