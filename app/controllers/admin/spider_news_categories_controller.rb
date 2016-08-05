class Admin::SpiderNewsCategoriesController < Admin::ApplicationController
  def index
    @page_title = "新闻抓取分类列表"
    @categories = ::MD::Source::SpiderNewsCategory.all.order(lvl: :desc)
  end

  def new
    @page_title = "新建新闻抓取分类"
    @category = ::MD::Source::SpiderNewsCategory.new
  end

  def create
    @page_title = "新建新闻抓取分类"
    @category = ::MD::Source::SpiderNewsCategory.new(permitted_params)
    if @category.save
      redirect_to action: :index
    else
      render action: :new
    end
  end

  def show
    @page_title = "查看新闻抓取分类详情"
    @category = ::MD::Source::SpiderNewsCategory.find(params[:id])
  end

  def edit
    @page_title = "编辑新闻抓取分类"
    @category = ::MD::Source::SpiderNewsCategory.find(params[:id])
  end

  def update
    @page_title = "编辑新闻抓取分类"
    @category = ::MD::Source::SpiderNewsCategory.find(params[:id])
    if @category.update(permitted_params)
      redirect_to action: :index
    else
      render action: :new
    end
  end

  def destroy
    ::MD::Source::SpiderNewsCategory.find(params[:id]).destroy
    redirect_to action: :index
  end
protected
  def permitted_params
    params.require(:md_source_spider_news_category).permit(:name, :lvl)
  end
end
