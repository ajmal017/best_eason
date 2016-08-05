class Admin::PtApplicationsController < Admin::ApplicationController
  def index
    @page_title = '实盘大赛申请表'
    @pt_apps = PtApplication.includes(:user).all
    @pt_apps = @pt_apps.where(status: params[:status]) if params[:status]
    @pt_apps = @pt_apps.order(id: :desc).paginate(page: params[:page] || 1, per_page: params[:per_page] || 20)
  end

  def show
    @page_title = '实盘大赛申请表'
    @pt_app = PtApplication.find(params[:id])
  end

  def approve
    @pt_app = PtApplication.find(params[:id])
    @pt_app.approved!
    respond_to do |format|
      format.js { render :update, locals: {notice: "设置成功:通过"} }
      format.html {redirect_to admin_pt_applications_path, notice: "设置成功:通过"}
    end
  end

  def notice
    @pt_app = PtApplication.find(params[:id])
    @pt_app.notice
    respond_to do |format|
      format.js { render :update, locals: {notice: "通知成功"} }
      format.html {redirect_to admin_pt_applications_path, notice: "通知成功"}
    end
  end

  def reject
    @pt_app = PtApplication.find(params[:id])
    @pt_app.rejected!
    respond_to do |format|
      format.js { render :update, locals: {notice: "设置成功:未通过"} }
      format.html {redirect_to admin_pt_applications_path, notice: "设置成功:未通过"}
    end
  end
end
