class TopicsController < ApplicationController
  #before_filter :authenticate_user!, only: [:show]
  before_action :set_main_menu
  before_action :find_topic, only: [:show]
  
  def index
    @topics = Topic.visible.sort_by_modified_at.paginate(page: params[:page], per_page: 8)
    @page_title = Topic::MARKETS[params[:market].to_s].to_s+'头条'
    @topics = @topics.where(market: params[:market]) if params[:market].present?
    @grouped_stocks = Topic.grouped_stocks_by(@topics.map(&:id))
    @recommend_topic = Recommend.topic || Topic.visible.last
    @recommend_basket = Recommend.basket || Basket.public_finished.last
    @recommend_stock_search = Recommend.stock_search
    @banner_infos = Recommend.banner_url_and_images
    @baskets = Basket.normal.public_finished.order(one_month_return: :desc).limit(5)
    @articles = Article.of_public.except_pony_report.order(post_date: :desc).limit(10)
    @market_indexes = ::StockIndex.all
    @background_color = "white"
  end

  def list
    redirect_to topics_path unless request.xhr?

    @topics = Topic.visible.sort.paginate(page: params[:page], per_page: 8)
    @topics = @topics.where(market: params[:market]) if params[:market].present?
    @grouped_stocks = Topic.grouped_stocks_by(@topics.map(&:id))
  end
  
  def show
    @commenters = $cache.fetch("cs:topic:#{@topic.id}:activest_users", expires_in: 10.minutes){ @topic.activest_users}
    @topic_stocks = @topic.topic_stocks.fixed.visible.includes(base_stock: [:stock_screener])
    @topic_stocks = @topic.topic_stocks.fixed.includes(base_stock: [:stock_screener]).limit(5) if @topic_stocks.blank?
    @basket_stock_ids = @topic_stocks.reject{|ts| ts.base_stock.trading_halt?}.sort_by{|ts| ts.hot_score}.reverse.map(&:base_stock_id).first(10)
    @articles = @topic.topic_articles.visible.includes(:article).limit(6).map(&:article)
    @articles_count = @topic.topic_articles.visible.count
    @page_title = "#{@topic.title} - 热点"
    @background_color = "white"
  end

  private
  def set_main_menu
    @top_menu_tab = "topics"
  end

  def find_topic
    @topic = Topic.find(params[:id])
  end

  def comment_params
    params.require(:comment).permit([:content])
  end
end
