class Admin::WeeklyReportsController < Admin::ApplicationController

  def new
  end

  def create
    response = Typhoeus.get(params[:url].strip)
    raise "request error!!!" unless response.success? && response.body.present?

    $redis.mapped_hmset(report_redis_key, report_attrs.merge(content: response.body))

    redirect_to admin_weekly_report_path(1)
  end

  def show
    @report = $redis.hgetall(report_redis_key)
  end

  def deliver
    if params[:mode] == "test" || !Rails.env.production?
      test_emails.each {|email| WeeklyReportSend.perform(email) }
    else
      User.where.not(last_sign_in_at: nil).order(:id).find_each do |user|
        next if user.email == "602814276@qq.com"
        Resque.enqueue(WeeklyReportSend, user.email)
      end
    end

    render js: "alert('success');window.location.reload();"
  end

  private

  def test_emails
    %w(dongshuxiang@caishuo.com dongshuxiang888@126.com)
  end

  def report_attrs
    {
      title: params[:title].strip, 
      url: params[:url]
    }
  end

  def report_redis_key
    "weekly_report"
  end
  
end
