class Admin::RecommendsController < Admin::ApplicationController

  before_action :auth_visit!

  def index
    @feed_categories = ::MD::FeedCategory.content.to_a
    @page_title = "推荐文章列表"

    @recommends = BaseRecommend.includes(:staffer).order(id: :desc)
    @recommends = @recommends.where(status: params[:status]) if params[:status].present?
    @recommends = @recommends.where(category_id: params[:category_id]) if params[:category_id].present?
    @recommends = @recommends.where(["title like ?", "%#{params[:title]}%"]) if params[:title].present?

    @recommends = @recommends.paginate(page: params[:page] || 1, per_page: params[:per_page] || 20).to_a
  end

  def show
    @page_title = "查看推荐文章"
    @recommend = BaseRecommend.find(params[:id])
  end

  def resend
    @recommend = BaseRecommend.find(params[:id])
    if @recommend.status == "error"
      @recommend.update(status: "pulling")
      @recommend.push_url
    end
    redirect_to action: :index
  end

  def new
    @page_title = "新建推荐文章"
    @recommend = BaseRecommend.new
  end

  def create
    @recommend = BaseRecommend.new(permit_recommend)
    @recommend.staffer = current_admin_staffer

    if @recommend.save
      redirect_to admin_recommends_path
    else
      render :new
    end
  end

  def edit
    @page_title = "编辑推荐文章"
    @recommend = BaseRecommend.find(params[:id])
  end

  def update
    @recommend = BaseRecommend.find(params[:id])
    @recommend.update(permit_recommend)
    redirect_to action: :index
  end

  def approve
    BaseRecommend.find(params[:id]).push_verifier(current_admin_staffer)
    redirect_to :back
  end

  private
  def permit_recommend
    params[:recommend].permit(:original_url, :category_id, :title, :published_at, :content, :source, :status)
  end

  def auth_visit!
    render_403 and return unless BaseRecommend.can_visit?(current_admin_staffer)
  end
end
