module Admin::ES
  class SpiderNewsController < Admin::ApplicationController

    def index
      p "--------------------------"
      sorts = ['published_at', 'created_at', '_score']
      query_str = "{query: {filtered: {query:{"
      if params[:index].present? ||  params[:category].present? || params[:q].present? || params[:qid].present? || params[:end_date].present? || params[:begin_date].present? || params[:processer].present?
        query_str += "bool:{ must:["
        query_str += "{match: {processer: 'civet'}}," if params[:processer].present?
        if params[:q].present?
          query_str += "{bool:{should:[{match: { title: params[:q]}}, {match: { content: params[:q]}}]}},"
          main_sort = '_score'
          @lock_sort = true
        end
        query_str += "{match: {source_id: params[:index]}}," if params[:index].present?
        query_str += "{match: {category_id: params[:category]}}," if params[:category].present?
        query_str += "{ids: { values: [params[:qid]] }}," if params[:qid].present?
        if params[:end_date].present? || params[:begin_date].present?
          begin_date = params[:begin_date].present? ? params[:begin_date] : '2000-01-01'
          end_date = params[:end_date].present? ? params[:end_date] : Date.today.to_s(:db)
          query_str += "{range: {published_at: { gte: '#{begin_date}', lte: '#{end_date}', format: 'yyyy-MM-dd', time_zone: '+8:00' }}}"
        end
        query_str += "]}"
      else
        query_str += "match_all: {}"
      end
      query_str += "},filter: {"
      query_str += "exists: {field: :pic_urls}" if params[:pic_urls_exists].present?
      query_str +="}}},highlight: {fields: {title:{}}}, sort: ["
      main_sort||=params[:sort]
      sorts = sorts.unshift(sorts.delete(main_sort)).compact
      sorts.each{|order| query_str+="{#{order}: :desc}," }
      query_str += "],facets:{sources:{terms:{field: :source_id,size: 1000,all_terms: true}},categories:{terms:{field: :category_id,size: 1000,all_terms: true}}}"
      query_str += "}"
      p query_str
      query = eval(query_str)
      p query.to_json
      @page_title = "新闻抓取"
      @spider_news = ::ES::SpiderNews.search(query, {type: nil}).paginate(page: params[:page]).per_page(20)
      @facets = @spider_news.response['facets']
      params[:sort] = sorts.first
    end

    def log
      @page_title = "抓取日志"
      @logs = ::MD::Report::SpiderNews.collection
      params[:date]||='today'
      case params[:date]
      when 'today'
        @begin_date = Date.today
      when 'yesterday'
        @begin_date = Date.yesterday
        @end_date = Date.yesterday
      when 'week'
        @begin_date = (Date.today-6)
      when 'month'
        @begin_date = (Date.today-29)
      else
        @begin_date = Date.parse('2012-01-01')
      end
      @end_date ||= Date.today
      es_query = {query: {range: {created_at: { gte: @begin_date, lte: @end_date, format: 'yyyy-MM-dd', time_zone: '+8:00' }}}, 
                  facets:{sources:{terms:{field: :source_class,size: 1000,all_terms: true}}}}
      @logs = ::ES::SpiderNews.search(es_query, search_type: 'count').response['facets']
    end

    def show
      @page_title = "查看新闻抓取详情"
      @spider_news = ::ES::SpiderNews.find(params[:id])
    end

    def sync
      @spider_news = ::ES::SpiderNews.find(params[:id])
      @spider_news.sync
      respond_to do |format|
        format.html { redirect_to [:admin, @spider_news], notice: '同步成功' }
        format.json { render text: "ok", status: :created }
      end
    end
      
    def edit
      @page_title = "修改新闻抓取"
      @spider_news = ::MD::Data::SpiderNews.find(params[:id])
      @stocks = BaseStock.where("id in (?)",@spider_news.stock_ids)
    end

    def update
      @page_title = "修改新闻抓取"
      @spider_news = ::MD::Data::SpiderNews.find(params[:id])
      if @spider_news.update_attributes(news_params)
        redirect_to [:admin, :es, :spider_news], notice: '更新成功.'
      else
        render :edit
      end
    end

    def sources
      @page_title = "新闻抓取源"
    end

    def sync_source
      Spider::Crawler.run(params[:id])
      redirect_to admin_es_sources_url, notice: '同步成功'
    end

    def news_params
      params[:md_data_spider_news][:stock_ids] = params[:md_data_spider_news][:stock_ids].split(',').flatten
      params[:md_data_spider_news][:pic_urls]||=[]
      params.require(:md_data_spider_news).permit(:source, :category_id, :tag_names, :title, :content, :published_at, stock_ids: [], pic_urls:[])
    end
  end
end
