class AccountMailer < BaseMailer
  include ApplicationHelper
  add_template_helper(MailHelper)

  def reset_password(user_id)
    @user = User.find(user_id)

    mail(:to => @user.email, :subject => '重新设定财说登录密码')
  end

  def confirmation_token(token_id)
    @user = EmailToken.find(token_id)
    mail(:to => @user.email, subject: '欢迎注册财说caishuo.com，请激活你的账号')
  end

  def rebind_email(user_id)
    @user = User.find(user_id)

    mail(:to => @user.rebind_email, :subject => '重新绑定财说电子邮箱')
  end

end
