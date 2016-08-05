class WeeklyReportSend
  @queue = :weekly_report

  def self.perform(email = nil)
    return if email.blank?

    report = $redis.hgetall(report_redis_key)

    deliver!(email, report["title"], report["content"])
  end
  
  def self.report_redis_key
    "weekly_report"
  end

  def self.deliver!(email, subject, body)
    raise "subject and body cannot blank!!!" if subject.blank? || body.blank?
    
    mail = Mail.new do
      from (Mail::Encodings.b_value_encode '财说', 'UTF-8').to_s  + '<from@sendcloud.com>'
      to email
      subject subject

      html_part do
        content_type 'text/html; charset=UTF-8'
        body body
      end
    end

    mail.delivery_method.settings.merge!(smtp_config)

    mail.deliver
  end

  def self.smtp_config
    {
      address: 'smtpcloud.sohu.com',
      port: 25,
      domain: 'sendcloud.org',
      user_name: 'postmaster@caishuo2.sendcloud.org',
      password: 'XutvRrzDnoIcCOYB',
      authentication: 'login'
    }
  end

end
