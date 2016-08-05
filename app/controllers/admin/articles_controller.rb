class Admin::ArticlesController < Admin::ApplicationController

  before_action :get_article, only: [:edit, :update, :sync, :toggle_viewable]

  def index
    @page_title = "财说专栏文章管理"
    @q = Article.includes(:categories).order("post_date desc").search(params[:q])
    @articles = @q.result.paginate(page: params[:page] || 1, per_page: params[:per_page] || 20).to_a
  end

  def new
    @page_title = "新建专栏文章"
    @stocks = []
    @article = Article.new
  end

  def create
    @page_title = "新建专栏文章"
    @article = Article.new
    if @article.intelligent_update(article_params)
      redirect_to admin_articles_path, notice: '新建成功.'
    else
      @stocks = BaseStock.where("id in (?)",@article.related_stocks.split(","))
      render :new
    end
  end

  def update_baskets
    @topic.update(basket_ids: params[:basket_ids].try(:join, ","))
    render text: "ok"
  end
  
  def edit
    @page_title = "修改专栏文章"
    @stocks = BaseStock.where("id in (?)",@article.related_stocks.split(","))
  end
  
  def update
    @page_title = "修改专栏文章"
    if @article.intelligent_update(article_params)
      redirect_to admin_articles_path, notice: '更新成功.'
    else
      @stocks = BaseStock.where("id in (?)",@article.related_stocks.split(","))
      render :edit
    end
  end

  def save_img
    @article_upload = Upload::Article.create(image: params[:image])
  end

  def crop_pic
    @article_upload = Upload::Article.find(params[:upload_article_id])
    @article_upload.update(params.require(:article).permit(:crop_x, :crop_y, :crop_w, :crop_h))
    @article_upload.save!
  end

  def sync_list
    Resque.enqueue(ArticleList, ArticleUrlCrawler::FIRST_PAGE)
  end
  
  def sync
    Resque.enqueue(Articles, @article.url)
  end
  
  def toggle_viewable
    @article.toggle_viewable!
  end
  
  private
  def article_params
    params.require(:article).permit(:url, :abstract, :title, :content, :related_stocks, :related_baskets, :post_date, :img, :temp_img_id, category: [])
  end

  def get_article
    @article ||= Article.find(params[:id])
  end
  
end
