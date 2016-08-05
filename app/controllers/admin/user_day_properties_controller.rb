class Admin::UserDayPropertiesController < Admin::ApplicationController
  before_action :set_user_day_property, only: [:show, :edit, :update, :destroy]

  def index
    @q = UserDayProperty.search(params[:q])
    @user_day_properties = @q.result.order(id: :desc).paginate(page: params[:page] || 1, per_page: params[:per_page] || 20)
  end

  def show
  end

  def new
    @user_day_property = UserDayProperty.new
  end

  def edit
  end

  def create
    @user_day_property = UserDayProperty.new(user_day_property_params)

    if @user_day_property.save
      redirect_to [:admin, @user_day_property], notice: 'User day property was successfully created.'
    else
      render :new
    end
  end

  def update
    if @user_day_property.update(user_day_property_params)
      redirect_to [:admin, @user_day_property], notice: 'User day property was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @user_day_property.destroy
    redirect_to admin_user_day_properties_url, notice: 'User day property was successfully destroyed.'
  end

  private
  
  def set_user_day_property
    @user_day_property = UserDayProperty.find(params[:id])
  end

  def user_day_property_params
    params.require(:user_day_property).permit(:user_id, :date, :total, :total_cash, :total_stocks_cost, :base_currency, :trading_account_id)
  end
end
