class ArticlesController < ApplicationController
  before_filter :authenticate_user!, only: [:comment]
  
  before_action :load_artice, only: [:comment]
  before_action :set_main_menu
  
  def index
    @category = Category.find_by(id: params[:category_id])
    @articles = Article.distinct.of_public.by_category(@category).order("post_date desc").includes(:categories).paginate(page: params[:page] || 1,  per_page: params[:per_page] || 20)
  end
  
  def show
    @category = Category.find_by(id: params[:category_id])
    @article = Article.of_public.find(params[:id])
    @article.increment!(:views_count)
    @related_stocks = BaseStock.where(id: @article.related_stocks.try(:split, ",")).includes(:stock_screener) || []
    @related_baskets = Basket.where(id: @article.related_baskets.try(:split, ",")) || []
    @page_title = "#{@article.title} - 财说专栏"
    @page_description = @article.description
  end
  
  def comment
    @comment = @article.comments.create(comment_params.merge(:user_id => current_user.id, replyable: @article)) if user_signed_in?
  end
  
  private
  def comment_params
    params.require(:comment).permit([:content])
  end
  
  def load_artice
    @article = Article.find(params[:id])
  end
  
  def set_main_menu
    @top_menu_tab = "articles"
    @body_class = "noneSelect"
  end
end
