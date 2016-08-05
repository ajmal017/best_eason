namespace :caishuo do

  def deliver_weekly_mail(user_emails, subject, body)
    mail = Mail.new do
      from (Mail::Encodings.b_value_encode '财说', 'UTF-8').to_s  + '<from@sendcloud.com>'
      to user_emails
      subject subject

      html_part do
        content_type 'text/html; charset=UTF-8'
        body body
      end 
    end

    mail.delivery_method.settings.merge!(batch_smtp_config)

    mail.deliver
  end

  def batch_smtp_config
    {
      address: 'smtpcloud.sohu.com', 
      port: 25, 
      domain: 'sendcloud.org', 
      user_name: 'postmaster@caishuo2.sendcloud.org',
      password: 'XutvRrzDnoIcCOYB', 
      authentication: 'login'
    }
  end

  desc 'send weekly report email to registered user'
  task :send_weekly_report => :environment do
    response = Typhoeus.get("https://www.caishuo.com/zt/newsletter_1505/email-seed-user-2.html")

    raise "request error!!!" unless response.success?

    subject = '财说一周精选：短期反弹是馅饼还是陷阱？'
    html_body = response.body
    puts html_body

    User.where.not(last_sign_in_at: nil).order(:id).find_each do |user|
      next if user.email == "602814276@qq.com"
      puts user.id
      deliver_weekly_mail(user.email, subject, html_body)
    end

  end

  desc "test send weekly report"
  task :test_send_weekly_report => :environment do
    response = Typhoeus.get("https://www.caishuo.com/zt/newsletter_1505/email-seed-user-2.html")
    raise "request error!!!" unless response.success?

    subject = '财说一周精选：短期反弹是馅饼还是陷阱？'
    html_body = response.body
    
    ['dongshuxiang@caishuo.com', 'dongshuxiang888@126.com', 'wangchangming@caishuo.com', 'mengyuan@caishuo.com', 'touch@caishuo.com'].each do |email|
      deliver_weekly_mail(email, subject, html_body)
    end
  end
end
