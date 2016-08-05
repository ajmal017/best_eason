require 'ostruct'
class Mobile::PagesController < Mobile::ApplicationController
  layout "mobile"

  before_action :hide_iclick, :hide_page_title_postfix

  def show
    raise ActionController::RoutingError, nil unless receive_scope.include? params[:type]
    @old_version = old_app_version?
    # debug: 排查网络问题
    render text: "没有内容" and return if params[:without_content].present?

    @hide_baidu = params[:without_baidu].present?
    
    send(params[:type])
    @page_title = "#{@result.title}"
  end

private

  def topics
    data = Topic.find(params[:id])
    @result = OpenStruct.new(data.show_info)
    @result.source = data.source
    # @page_title = "#{@result.title} - 头条"
    click_feed_hub(data)
  end

  def articles
    data = Article.find(params[:id])
    @result = OpenStruct.new(data.show_info)
    @result.source = "财说"
    # @page_title = "#{@result.title} - 文章"
    click_feed_hub(data)
  end

  def announcements
    data = RestClient.api.stock.announcement.find(params[:id])
    @result = OpenStruct.new({
      title: data["info_title"],
      content: RestClient.api.stock.announcement.content(params[:id]),
      modified_at: (Time.parse(data["info_publ_date"]) rescue data["info_publ_date"]),
    })
    # @page_title = "#{@result.title} - 公告"
  end

  def news
    data = MD::Data::SpiderNews.find(params[:id])
    click_feed_hub(data)
    
    data = data.as_news_json
    @result = OpenStruct.new({
      title: data["title"],
      tag: data["category"],
      content: data["content"],
      source: data["source"],
      modified_at: (Time.parse(data["published_at"]) rescue data["published_at"]),
      original_url: data["url"]
    })
    # @page_title = "#{@result.title} - 新闻"

  end

  def receive_scope
    ::Page::TYPE
  end

  def click_feed_hub(source)
    MD::FeedHub.click(source.class.to_s, source.id, app_uuid) if mobile_request?
  end

end
