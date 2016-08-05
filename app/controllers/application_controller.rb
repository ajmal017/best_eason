class ApplicationController < ActionController::Base
  include Authentication::Base

  helper_method :counter, :mobile_link, :mobile_request?, :md_data_spider_news_url, :channel

  # before_action :mobile_redirect

  before_filter :current_user
  before_filter :init_publisher_config, :redirect_when_user_blocked, unless: 'request.xhr?'
  # before_action :require_stock_bar
  before_action :require_site_search
  before_action :load_locale
  before_action :set_client_type, :set_channel_cookie
  before_action :require_body_class
   
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  
  rescue_from ActionController::InvalidAuthenticityToken do |exception|
    redirect_to login_path 
  end

  def set_client_type
    @client_type = 'app' if %w{com.caishuo.stock.debug com.caishuo.stock}.include?(request.env['HTTP_X_REQUESTED_WITH'])
  end

  def set_channel_cookie
    cookies[:c] = {value: params[:channel], expires: 6.hours.from_now, domain: :all, httponly: true} if params[:channel].present?
  end

  def channel
    cookies[:c]
  end

  def mobile_request?
    @client_type == 'app'
  end

  def mobile_redirect
    cookies['fr'] = params[:fr] if params[:fr].present?
    protocol = (request.protocol rescue 'https://')
    redirect_to "#{protocol}#{$mobile_domain}#{get_mobile_link}" and return if cookies['fr'] != "mobile" and is_mobile?
  end

  def get_mobile_link
    rules = {
      "/events/shipan" => "/events/shipan"
    }
    mobile_link(rules[request.path]) rescue nil
  end

  def set_mobile_link(url_path)
    @mobile_link = "#{$mobile_host}#{url_path}?fr=www"
  end

  def is_mobile?
    request.env['HTTP_USER_AGENT'].to_s.match(/(Android|iPod|iPhone|iPad|mobile|iOS)/)
  end

  # def is_app?
  #   is_mobile? and 
  # end

  def hide_iclick
    @hide_iclick = true
  end

  def load_locale
    gon.locale = I18n.locale = check_locale
  end

  def check_locale
    cookies['i18n.LOCALE'] ||= request.headers["X-Language"]
    cookies['i18n.LOCALE'] == 'zh-TW' ? 'zh-TW' : 'zh-CN'
  end

  def no_route
    render_404
  end

  def init_publisher_config
    gon.publisher = Publisher.stomp
    gon.publisher[:events] = []
    gon.current_user_id = @current_user.try(:pretty_id)
  end

  # Demo:
  # add_publisher_events('stock_index')
  def add_publisher_events(*events)
    gon.publisher[:events].push(*events).uniq!
  end

  def require_stock_bar
    return if request.xhr?
    @require_stock_bar = true
    @stock_bar_data = ::StockIndex.all
    add_publisher_events('stock_index')
  end

  def require_site_search
    @require_site_search = @current_user.present?
  end

  def require_body_class
    return if request.xhr?
    if /Mac\ OS/.match(request.user_agent)
      @body_class = "WB_macT"
    elsif /Windows\ XP/.match(request.user_agent)
      @body_class = "WB_xpT"
    end
  end

  def render_404
    render_optional_error_file(404)
  end

  def render_403
    render_optional_error_file(403)
  end

  def counter
    return nil if current_user.blank?
    @unread_counter ||= Counter.find_by(user_id: current_user.id)
  end

  # 设置load_asset_file加载规则
  def use_controller_javascript(path)
    @controller_javascript_path = path
  end

  # 根据传参locale进行国际化
  def set_locale
    if @current_user.present?
      locale = @current_user.locale rescue cookies["i18n.LOCALE"]
    else
      locale = cookies["i18n.LOCALE"]
      locale = request.env['HTTP_ACCEPT_LANGUAGE'].scan(/^[a-z]{2}/).first rescue 'zh-CN' if locale.blank?
    end
    locale ||= 'zh-CN'
    locale = "zh-CN" if locale == "zh_CN"
    I18n.locale = locale.match('zh-TW') ? 'zh-TW' : 'zh-CN'
    # I18n.locale = extract_locale_from_accept_language_header
  end

  private

  # 登录跳转路径
  def after_sign_in_path_for(resource)
    if resource.is_a?(Admin::Staffer)
      admin_root_path
    elsif request.path == user_confirmation_path
      account_profile_path
    else
      stored_location_for(resource) || root_path
    end
  end

  # 退出跳转路径
  def after_sign_out_path_for(resource)
    if resource == :admin_staffer
      new_admin_staffer_session_path
    else
      root_path
    end
  end

  
  def render_optional_error_file(status_code)
    @background_color = "white"
    status = status_code.to_s
    if status == "404"
      @page_title = "对不起，您访问的页面没有找到。"
      render :template => "/shared/errors/404.html.erb", :format => [:html], :handler => [:erb], :status => status
    else
      @page_title = "对不起，服务器看起来出了点小故障，请稍候再访问。"
      render :template => "/shared/errors/500.html.erb", :format => [:html], :handler => [:erb], :status => status
    end
  end

  def mobile_link(url_path)
    return url_path if request.blank? or request.host != $mobile_domain
    protocol = (request.protocol rescue 'https://')
    url_path.to_s.sub(/\/mobile/, "#{protocol}#{$mobile_domain}")
  end

  # mobile to PC Link
  def pc_link(obj_or_url)
    return url_path if request.blank? or request.host != $mobile_domain
    url_path = url_path.to_s.sub(/\/mobile/, Setting.host)
    "#{url_path}?fr=mobile"
  end

  def destroy_return_to
    cookies.delete(:return_to)
  end

  rescue_from StandardError, :with => :rescue_action if Rails.env.production?
  def rescue_action(exception)
    case exception
    when ActiveRecord::RecordNotFound,
        ActionController::RoutingError,
        AbstractController::ActionNotFound,
        Elasticsearch::Persistence::Repository::DocumentNotFound
      status = '404 Not Found'
      @page_title = "对不起，您访问的页面没有找到。"
    when ActiveRecord::RecordInvalid,
        ActiveRecord::RecordNotSaved,
        ActionController::InvalidAuthenticityToken,
        ActiveRecord::StaleObjectError,
        ActionController::MethodNotAllowed,
        ActionController::NotImplemented
      @page_title = "对不起，该请求无法处理。"
      status = '422 Unprocessable Entity'
    else
      @page_title = "对不起，服务器看起来出了点小故障，请稍候再访问。"
      status = '500 Internal Server Error'
      NewRelic::Agent.notice_error(exception, {uri: request.fullpath, referer: request.original_url, request_params: request.query_parameters})
      render(:template => '/shared/errors/500.html.erb', :status => status) and return 
    end

    render :template => '/shared/errors/404.html.erb', :status => status
  end

  rescue_from Authentication::UserBlocked do
    redirect_to feedback_about_index_path
  end

  def redirect_when_user_blocked
    if current_user && current_user.blocked? && !["about", "sessions"].include?(controller_name) && !(params[:controller] =~ /^admin/)
      redirect_to feedback_about_index_path and return
    end
  end
end
