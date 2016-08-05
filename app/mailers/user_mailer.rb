class UserMailer < BaseMailer
  include ApplicationHelper
  add_template_helper(MailHelper)

  def landing(landing_id)
    @landing = Landing.find(landing_id)
    return false if @landing.blank?
    title = '恭祝您抢得财说的先机邀请，您的主题投资之旅即将夺人而启'
    mail(:to => @landing.email, :subject => title)
  end

  # 邀请大V邮件
  def invite_seed_user(lead_id)
    lead = Lead.find(lead_id)
    @invite_code = lead.invitation_codes.order(id: :desc).first.try(:code)
    msg = mail(:to => lead.email, subject: '致财说首批用户')
    msg.delivery_method.settings[:user_name] = 'postmaster@caishuo2.sendcloud.org'
    msg
  end

  def reset_password_email(user)
    @greeting = "Hi"

    mail to: "dongshuxiang888@126.com"
  end

  def seed_user_upgrade(email)
    msg = mail(:to => email, subject: '致财说首批用户')
    msg.delivery_method.settings[:user_name] = 'postmaster@caishuo2.sendcloud.org'
    msg
  end
end
