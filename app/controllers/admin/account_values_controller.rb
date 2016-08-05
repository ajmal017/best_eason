class Admin::AccountValuesController < Admin::ApplicationController
  before_action :set_account_value, only: [:show, :edit, :update, :destroy]

  def index
    @q = AccountValue.search(params[:q])
    @account_values = @q.result.order(id: :desc).paginate(page: params[:page] || 1, per_page: params[:per_page] || 20)
  end

  def show
  end

  def new
    @account_value = AccountValue.new
  end

  def edit
  end

  def create
    @account_value = AccountValue.new(account_value_params)

    if @account_value.save
      redirect_to [:admin, @account_value], notice: 'Account value was successfully created.'
    else
      render :new
    end
  end

  def update
    if @account_value.update(account_value_params)
      redirect_to [:admin, @account_value], notice: 'Account value was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @account_value.destroy
    redirect_to admin_account_values_url, notice: 'Account value was successfully destroyed.'
  end

  private
  
  def set_account_value
    @account_value = AccountValue.find(params[:id])
  end

  def account_value_params
    params.require(:account_value).permit(:user_id, :broker_user_id, :key, :currency, :value, :user_binding_id, :trading_account_id)
  end
end
