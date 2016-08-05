class Account::RegistrationsController < Account::BaseController
  layout 'application'
  
  before_filter :check_permission, :set_page_class, only: [:new, :create]

  def new
    
  end

  def create
    @page_title = "注册账号"
    @user = User.new({channel_code: cookies[:c]}.merge(user_params))
    if @user.mobile.present?

      if Sms.verifty(@user.mobile, params[:user][:captcha]) && @user.save
        session[:new_user] = true
        sign_in!(@user) and redirect_to new_account_profile_path and return
      else
        flash[:alert] = "验证码不正确"
        render action: :new and return
      end

    elsif @user.email.present?

      @fake_user = EmailToken.find_or_initialize_by(email: user_params[:email], confirmed_at: nil)
      if invite_code_valid? && valid_captcha?(params[:user][:captcha]) && !User.exists?(email: user_params[:email]) && @fake_user.update(invite_code: user_params[:invite_code], channel_code: @user.channel_code)
        redirect_to account_confirmations_path(email: @user.email) and return
      else
        render action: :new and return
      end

    end
  end

  def activate
    @page_title = "激活后台邮箱"
  end

  private

  def user_params
    params.require(:user).permit(:email, :username, :avatar, :password, :password_confirmation, :invite_code, :mobile)
  end

  def invite_code_valid?
    InvitationCodeSuper.code_valid?(params[:user][:invite_code]) || params[:user][:invite_code].blank?
  end

  def check_permission
    redirect_to root_path if current_user.present?
  end

  def set_page_class
    @background_color = "white"
    @header_class = "login_head"
  end
end
