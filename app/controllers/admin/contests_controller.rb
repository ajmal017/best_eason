class Admin::ContestsController < Admin::ApplicationController
  before_action :set_contest, only: [:show, :edit, :update, :destroy, :import, :do_import, :cash, :update_cash]

  def index
    @page_title = '大赛列表'
    @q = Contest.includes(:broker).search(params[:q])
    @contests = @q.result.order(id: :desc).paginate(page: params[:page] || 1, per_page: params[:per_page] || 20)
  end

  def show
    @page_title = '大赛列表'
  end

  def new
    @page_title = '新建大赛'
    @contest = Contest.new
  end

  def edit
    @page_title = '编辑大赛'
  end

  def create
    @contest = Contest.new(contest_params)

    if @contest.save
      redirect_to [:admin, @contest], notice: '大赛已创建'
    else
      @page_title = '新建大赛'
      render :new
    end
  end

  def update
    if @contest.update(contest_params)
      redirect_to [:admin, @contest], notice: '大赛已更新'
    else
      @page_title = '编辑大赛'
      render :edit
    end
  end

  def destroy
    @contest.destroy
    redirect_to admin_contests_url, notice: '大赛已删除'
  end

  def cash
    @page_title = '更新奖金池'
  end

  def update_cash
    @page_title = '更新奖金池'
    @contest.set_contest_cash(params[:cash]) if params[:cash]
    redirect_to action: :index
  end

  def import
    @page_title = '导入大赛用户'
  end

  def do_import
    @page_title = '导入大赛用户'
    @contest.update(contest_params) && @data = @contest.import
    render :import
  end

  def sync_asset
    RestClient.trading.pt.sync_asset(params[:id])
    redirect_to :back
  end

  private
  
  def set_contest
    @contest = Contest.find(params[:id])
  end

  def contest_params
    params.require(:contest).permit(:status, :name, :start_at, :end_at, :broker_id, :users_count, :total_invest, :players_csv, :players_area)
  end
end
