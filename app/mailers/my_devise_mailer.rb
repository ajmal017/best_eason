class MyDeviseMailer < Devise::Mailer
  include ApplicationHelper
  include Devise::Controllers::UrlHelpers
  add_template_helper(MailHelper)
  
  def confirmation_instructions(record, token, opts = {})
    opts[:from] = default_email_sender
    opts[:reply_to] = Setting.email_reply
    opts[:subject] = '欢迎注册财说caishuo.com，请激活你的账号'
    super
  end

  def reset_password_instructions(record, token, opts={})
    opts[:from] = default_email_sender
    opts[:reply_to] = Setting.email_reply
    opts[:subject] = '重新设定财说登录密码'
    super
  end
end
