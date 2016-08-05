class NewsController < ApplicationController
  def show
    @news = MD::Data::SpiderNews.find(params[:id]).as_news_json
    @base_stocks = BaseStock.where(id: @news["stock_ids"]).limit(5) rescue []
    @page_title = "新闻-" + @news['title']
  end
end
