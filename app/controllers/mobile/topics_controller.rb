class Mobile::TopicsController < Mobile::ApplicationController
  layout 'mobile'

  def show
    @topic = Topic.find(params[:id])

    @page_title = "#{@topic.title} - 新闻"

    @topic_stocks = @topic.topic_stocks.fixed.visible.includes(base_stock: [:stock_screener])
    @topic_stocks = @topic.topic_stocks.fixed.includes(base_stock: [:stock_screener]).limit(5) if @topic_stocks.blank?
    @topic_baskets = @topic.selected_topic_baskets.includes(:author, :tags)
  end
end
