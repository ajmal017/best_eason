class Admin::PanelsController < Admin::ApplicationController
  def index
    @page_title = "推荐面板"
    @panels = Panel.all
  end

  def update_all
    params[:panel].each do |p|
      Panel.new(p).save
    end
    redirect_to "/admin/panels"
  end

  def edit_all
    @page_title = "修改推荐面板"
    @panels = Panel.all
  end

end
