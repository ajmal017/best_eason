class Market::Zxg::TopicsController < Market::BaseController
  caches_page :show

  def show
    @topic = Topic.find(params[:id])
    @topic_stocks = @topic.topic_stocks.fixed.visible.includes(base_stock: [:stock_screener]).limit(3)
    @topic_stocks = @topic.topic_stocks.fixed.includes(base_stock: [:stock_screener]).limit(3) if @topic_stocks.blank?
    @chart_datas = @topic_stocks.map{|ts| ts.base_stock }.map{|s| [s.id, s.five_day_chart_datas] }.to_h

    @page_title = @topic.full_title
  end
end