class Admin::PushsController < Admin::ApplicationController

  def index
    @page_title = "极光推送"
    @push_logs = PushLog.desc
    @push_logs = @push_logs.send(params[:status]) if params[:status]
    @push_logs = @push_logs.by_staffer(params[:staffer_id]) if params[:staffer_id]
    @push_logs = @push_logs.includes(:staffer).paginate(page: params[:page] || 1, per_page: params[:per_page] || 20).to_a
  end

  def new
    @page_title = "极光推送"
    @push_log = PushLog.new
  end

  def create
    @push_log = PushLog.new permit
    @push_log.staffer_id = current_admin_staffer.id
    if @push_log.save
      redirect_to admin_pushs_path
    else
      render :new
    end
  end

private
  def permit
    params[:push_log].permit(:push_key, :push_type, :content, :password)
  end

end
