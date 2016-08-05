class Admin::SmsContentsController < Admin::ApplicationController
  def index
    @page_title = "回复短信内容"
    @q = SmsContent.order("id desc").created_at_gte(params[:created_at_gteq]).created_at_lte(params[:created_at_lteq]).search(params[:q])
    @paginated_sms_contents = @q.result.paginate(page: params[:page] || 1, per_page: params[:per_page] || 30)
  end
end
