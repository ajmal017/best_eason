class Admin::PositionArchivesController < Admin::ApplicationController

  def index
    @page_title = "交易账号绑定记录"

    @q = PositionArchive.order(id: :desc).search(params[:q])
    @position_archives = @q.result.paginate(page: params[:page] || 1, per_page: params[:per_page] || 20).to_a
  end

  def archive
    Archive::Position.perform(params[:market], params[:date])

    render js: "alert('succ');window.location.reload();"
  end

end
