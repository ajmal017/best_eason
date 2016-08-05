module Admin::ES
  class NewsController < Admin::ApplicationController

    def index
      if params[:site].present?
        query = {query: { match: { source: params[:site] } }, sort: {updated_at: {order: "desc"}}}
      elsif params[:q].present?
        query = {query: { match: { title: params[:q] } }, :highlight=>{:fields=>{:title=>{}}}}
      else
        query = {query: { match_all: {} }, sort: {updated_at: {order: "desc"}}}
      end
      @page_title = "新闻"
      @news = ::ES::News.search(query).paginate(page: params[:page]).per_page(20)
      @sources = ::ES::News.search({facets: { sources: { terms: { field: :source, size: 1000, all_terms: true } } }}, { search_type: :count }).response["facets"]["sources"]["terms"]
    end


    def show
      @page_title = "查看新闻详情"
      @news = ::ES::News.find(params[:id])
    end

    def sync
      @news = ::ES::News.find(params[:id])
      @news.sync
      respond_to do |format|
        format.html { redirect_to [:admin, @news], notice: '同步成功' }
        format.json { render text: "ok", status: :created }
      end
    end
      
    def edit
      @page_title = "修改新闻"
      @news = ::ES::News.find(params[:id])
    end

    def update
      @page_title = "修改新闻"
      @news = ::ES::News.find(params[:id])
      if @news.update(params[:es_news])
        redirect_to [:admin, @news], notice: '更新成功.'
      else
        render :edit
      end
    end

    def sources
      @page_title = "新闻源"
    end

    def sync_source
      Spider::Crawler.run(params[:id])
      redirect_to admin_es_sources_url, notice: '同步成功'
    end


  end
end
