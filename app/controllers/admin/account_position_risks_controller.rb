class Admin::AccountPositionRisksController < Admin::ApplicationController
  before_action :set_account_position_risk, only: [:show, :edit, :update, :destroy]

  def index
    @q = AccountPositionRisk.search(params[:q])
    @account_position_risks = @q.result.order(id: :desc).paginate(page: params[:page] || 1, per_page: params[:per_page] || 20)
  end

  def show
  end

  def new
    @account_position_risk = AccountPositionRisk.new
  end

  def edit
  end

  def create
    @account_position_risk = AccountPositionRisk.new(account_position_risk_params)

    if @account_position_risk.save
      redirect_to [:admin, @account_position_risk], notice: 'Account position risk was successfully created.'
    else
      render :new
    end
  end

  def update
    if @account_position_risk.update(account_position_risk_params)
      redirect_to [:admin, @account_position_risk], notice: 'Account position risk was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @account_position_risk.destroy
    redirect_to admin_account_position_risks_url, notice: 'Account position risk was successfully destroyed.'
  end

  private
  
  def set_account_position_risk
    @account_position_risk = AccountPositionRisk.find(params[:id])
  end

  def account_position_risk_params
    params.require(:account_position_risk).permit(:stock_focus_score, :industry_focus_score, :plate_focus_score, :trading_account_id, :date, :var95, :basket_fluctuation)
  end
end
