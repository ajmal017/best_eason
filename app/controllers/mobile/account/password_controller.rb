class Mobile::Account::PasswordController < Mobile::ApplicationController
  layout 'mobile/accounts'

  def new
    @page_title = "重设密码"
  end

  def create
    @result = params["email_or_phone"]
    redirect_to :back and return unless @result.present?

    if @result =~ /^((\+86)|(86))?\d{11}$/ # 手机号
      if User.find_by(mobile: @result).present?
        @body_class = "gray"
        render "phone"
      else
        render action: :new
      end
    elsif @result =~ /^([^@\s]+)@((?:[a-z0-9-]+\.)+[a-z]{2,})$/ # 邮箱

      @user = User.find_by(email: @result)
      @body_class = "gray"
      if @user && @user.send_reset_password
        render "email" if User.find_by_email(@result).present?
      else
        render action: :new
      end
    end

  end

  def reset_password
    @page_title = "邮件密码重置"
    @body_class = "gray"
    @user = User.find_by(reset_password_token: params[:reset_password_token])
  end

  # 手机号修改密码
  def update_password_by_mobile
    @user = User.find_by_mobile(params[:mobile])

    result = false
    if Sms.verifty(params[:mobile], params[:captcha])
      if @user.reset_password!(params[:password], params[:password_confirmation], false)
        result = true
      else
        msg = "修改密码失败"
      end
    else
      msg = "验证码不正确"
    end

    render json: {status: result, msg: msg}
  end

  def send_reset_password_email
    @user = User.find_by(email: params[:email])

    result = @user && @user.send_reset_password

    render json: {status: result}
  end

  # 邮箱修改密码
  def update_password_by_email
    user = User.reset_password_by_token(user_params)

    result = false
    if user.valid?
      result = true
    else
      msg = "重置邮箱链接已经失效"
    end
    render json: {status: result, msg: msg}
  end

  def update_password
    if current_user.reset_password!(params[:password], params[:password_confirmation], false)
      redirect_to "/mobile/account/password/finish"
    else
      redirect_to :back
    end
  end

  def finish
    @page_title = "密码修改成功"
    @body_class = "gray"
  end

  def change_password
    authenticate_user!
  end

  private
  def user_params
    params.permit(:password, :password_confirmation, :reset_password_token)
  end
end
