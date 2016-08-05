class Admin::MajiaUsersController < Admin::ApplicationController
  before_action :set_majia_user, only: [:show, :edit, :update, :destroy]

  def index
    @q = MajiaUser.includes(:user).search(params[:q])
    @majia_users = @q.result.order(id: :desc).paginate(page: params[:page] || 1, per_page: params[:per_page] || 20)
  end

  def show
  end

  def new
    @majia_user = MajiaUser.new
  end

  def edit
  end

  def create
    @majia_user = MajiaUser.new(majia_user_params)

    if @majia_user.save
      redirect_to [:admin, @majia_user], notice: 'Majia user was successfully created.'
    else
      render :new
    end
  end

  def update
    if @majia_user.update(majia_user_params)
      redirect_to [:admin, @majia_user], notice: 'Majia user was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @majia_user.destroy
    redirect_to admin_majia_users_url, notice: 'Majia user was successfully destroyed.'
  end

  private
  
  def set_majia_user
    @majia_user = MajiaUser.find(params[:id])
  end

  def majia_user_params
    params.require(:majia_user).permit(:user_id, :email, :password, :username, :gender, :province, :city, :headline, :orientation, :concern, :duration)
  end
end
