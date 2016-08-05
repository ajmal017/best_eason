class Admin::UserProfitsController < Admin::ApplicationController
  before_action :set_user_profit, only: [:show, :edit, :update, :destroy]

  def index
    @q = UserProfit.search(params[:q])
    @user_profits = @q.result.order(id: :desc).paginate(page: params[:page] || 1, per_page: params[:per_page] || 20)
  end

  def show
  end

  def new
    @user_profit = UserProfit.new
  end

  def edit
  end

  def create
    @user_profit = UserProfit.new(user_profit_params)

    if @user_profit.save
      redirect_to [:admin, @user_profit], notice: 'User profit was successfully created.'
    else
      render :new
    end
  end

  def update
    if @user_profit.update(user_profit_params)
      redirect_to [:admin, @user_profit], notice: 'User profit was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @user_profit.destroy
    redirect_to admin_user_profits_url, notice: 'User profit was successfully destroyed.'
  end

  private
  
  def set_user_profit
    @user_profit = UserProfit.find(params[:id])
  end

  def user_profit_params
    params.require(:user_profit).permit(:user_id, :today_pnl, :total_pnl, :date, :trading_account_id)
  end
end
