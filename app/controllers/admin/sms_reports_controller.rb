class Admin::SmsReportsController < Admin::ApplicationController
  def index
    @page_title = "短信发送状态"
    @q = SmsReport.order("id desc").created_at_gte(params[:created_at_gteq]).created_at_lte(params[:created_at_lteq]).search(params[:q])
    @paginated_sms_reports = @q.result.paginate(page: params[:page] || 1, per_page: params[:per_page] || 30)
  end
end
