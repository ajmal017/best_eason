class Account::ConfirmationsController < Account::BaseController
  layout 'application'

  def index
  end

  def new
  end

  def create
    @user = EmailToken.find_by(email: params[:user][:email])
    @user && @user.resend_confirmation_email
  end

  def pass
    @user = User.check_confirmation_token(params[:confirmation_token])
    if @user.errors.empty?
      sign_in!(@user) and redirect_to new_account_user_path and return
    end
  end

  def rebind_email
    user = User.rebind_email_by_token(params.permit(:rebind_email_token))
    @result = user.errors.blank? && user.valid?
    @page_title = @result ? "邮箱绑定成功" : "邮箱绑定失败"
  end

end
