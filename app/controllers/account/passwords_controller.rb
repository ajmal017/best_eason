class Account::PasswordsController < Account::BaseController
  
  layout 'application'

  def new
    @page_title = "密码找回"
    @background_color = "white"
  end

  def create
    password_type = params[:user][:email].present? ? "email" : "mobile"

    @user =
      if password_type == "email"
        User.find_by(email: params[:user][:email])
      else
        User.find_by(mobile: params[:user][:mobile])
      end

    respond_to do |format|
      if @user && (password_type == "email" ? @user.send_reset_password : (Sms.verifty(@user.mobile, params[:user][:captcha]) && @user.send_reset_password_with_mobile))
        format.html { redirect_to(password_type == "email" ? account_password_path(email: @user.email) : edit_account_password_url(reset_password_token: @user.reset_password_token)) }
      else
        format.html { render action: :new }
      end

      format.js
    end
  end

  def show
    @background_color = "white"
  end

  def edit
    @background_color = "white"
    @user = User.find_by(reset_password_token: params[:reset_password_token])
  end
  
  def update
    user = User.reset_password_by_token(user_params)
    if user.valid?
      sign_in!(user) and redirect_back_to(cookies[:return_to],root_path)
    else
      redirect_to edit_account_password_path, notice: '重置密码邮件已经失效'
    end
  end
  
  private

  def user_params
    params.require(:user).permit(:password, :password_confirmation, :reset_password_token)
  end
end
