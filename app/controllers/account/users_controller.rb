class Account::UsersController < Account::BaseController
  before_filter :authenticate_user!, except: [:new, :create]
  before_filter :check_permission, only: [:create]
  
  layout 'application'

  def new
    redirect_to root_path and return if user_signed_in?
    @fake_user = EmailToken.check_confirmation_token(params[:confirmation_token], false)
  end

  def create
    @user = User.new(user_params.merge(email: @fake_user.email, invite_code: @fake_user.invite_code, channel_code: @fake_user.channel_code))
    if @user.save
      @user.follow_caishuo
      sign_in!(@user) and @user.do_reset_confirmation_token! and redirect_back_to(params[:return_to]||cookies[:return_to], new_account_profile_path) and destroy_return_to and return
    else
      render :new
    end
  end

  def update
    if user_params[:password].present?
      @ret = (current_user.encrypted_password.blank? || current_user.valid_current_password?(user_params[:current_password])) && current_user.update(user_params)
      p current_user.errors
    else
      @ret = current_user.update(user_params)
    end

    respond_to do |format|
      format.js
    end
  end

  private

  def user_params
    params.require(:user).permit(:password, :password_confirmation, :current_password, :username, :gender)
  end

  def check_permission
    @fake_user = EmailToken.check_confirmation_token(params[:confirmation_token], false)
    redirect_to root_path and return unless @fake_user.persisted? && @fake_user.errors.empty?
  end
end
