class IndexController < ApplicationController
  layout "landing"

  skip_before_action :require_stock_bar
  
 
  def index
    #redirect_to topics_path and return if user_signed_in?
    # 爬虫render页面
    unless request.user_agent.present? && request.user_agent =~ /baidu|sogou|haosou|bot|CaishuoAgent/
      redirect_to topics_path(params.except(:controller, :action)) and return
    end
    #@top_menu_tab = 'index'
    #@background_color = 'siteIndex'

    #@require_stock_bar = false 
    
    @landing = Landing.new
    @page_title = "财说，最好用的全球股票交易平台"

    use_controller_javascript false
  end


  def unicorn_signup
    redirect_to @current_user.present? ? "http://www.unicornsecurities.hk/?from=caishuo" : "/signup"
  end


  # 自动判断PC、Mobile
  # PC到 www.caishuo.com
  # Mobile到 m.caishuo.com
  # 重定向
  # Demo:
  # www.caishuo.com/go?url=/app&channel=yy&utm_source=yy&utm_medium=social&utm_campaign=weibo
  # yy 运营部门所写
  # utm_medium:  social 
  # utm_campaign: weibo weixin sms 
  def go
    render text: '缺少参数' and return if params[:url].blank?
    url = CGI::unescape(params[:url])
    attrs = request.GET.except(:url)
    host = is_mobile? ? $mobile_host : Setting.host
    if url =~ /\?/
      redirect_to "#{host}#{url}&#{attrs.to_query}"
    else
      redirect_to "#{host}#{url}?#{attrs.to_query}"
    end 
  end

end
