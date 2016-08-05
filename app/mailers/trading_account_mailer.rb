class TradingAccountMailer < BaseMailer
  include ApplicationHelper
  add_template_helper(MailHelper)

  def bind(user_broker_id)
    @account = TradingAccount.find(user_broker_id)
    @user = User.find(@account.user_id)

    mail(:to => @account.email, :subject => '财说证券交易账号绑定')
  end

end
