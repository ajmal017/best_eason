class Admin::SpiderNewsSourcesController < Admin::ApplicationController
  def index
    @page_title = "新闻抓取来源列表"
    @sources = ::MD::Source::SpiderNewsSource.includes(:category).order(category_id: :desc)
    @sources = ::MD::Source::SpiderNewsSource.includes(:category).all.order(category_id: :desc).all
    @sources = @sources.where(category_id: params[:category_id]) if params[:category_id]
    @sources = @sources.where(status: params[:status]) if params[:status]
    es_query = {query: {range: {created_at: { gte: Date.today.to_s(:db), lte: Date.today.to_s(:db), format: 'yyyy-MM-dd', time_zone: '+8:00' }}}, 
                facets:{sources:{terms:{field: :source_id,size: 1000,all_terms: true}}}}
    @logs = ::ES::SpiderNews.search(es_query, search_type: 'count').response['facets']['sources']['terms'].inject(Hash.new(0)){|hsh, facet| hsh[facet['term']] = facet['count']; hsh }
  end

  def new
    @page_title = "新建新闻抓取来源"
    @source = ::MD::Source::SpiderNewsSource.new
  end

  def create
    @page_title = "新建新闻抓取来源"
    @source = ::MD::Source::SpiderNewsSource.new(permitted_params)
    if @source.save
      redirect_to action: :index
    else
      render action: :new
    end
  end

  def show
    @page_title = "查看新闻抓取来源详情"
    @source = ::MD::Source::SpiderNewsSource.find(params[:id])
  end

  def edit
    @page_title = "编辑新闻抓取来源"
    @source = ::MD::Source::SpiderNewsSource.find(params[:id])
  end

  def update
    @page_title = "编辑新闻抓取来源"
    @source = ::MD::Source::SpiderNewsSource.find(params[:id])
    if @source.update(permitted_params)
      redirect_to action: :index
    else
      render action: :new
    end
  end

  def run
    RestClient.api.tool.run_spider_news_source(params[:id])
    redirect_to action: :index
  end

  def destroy
    ::MD::Source::SpiderNewsSource.find(params[:id]).stopped!
    redirect_to action: :index
  end
protected
  def permitted_params
    params.require(:md_source_spider_news_source).permit(:name, :crawler_name, :list_page_url, :source_name, :interval_time, :auto_adjust, :category_id)
  end
end
