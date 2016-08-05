class Admin::AdminLogsController < Admin::ApplicationController
  before_action :set_admin_log, only: [:show]

  def index
    @q = AdminLog.search(params[:q])
    @admin_logs = @q.result.order(id: :desc).paginate(page: params[:page] || 1, per_page: params[:per_page] || 20)
  end

  def show
  end

  private
  
  def set_admin_log
    @admin_log = AdminLog.find(params[:id])
  end

end
