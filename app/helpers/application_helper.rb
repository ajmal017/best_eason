module ApplicationHelper

  def nav_positions_path
    (@current_user and TradingAccount.exists?(user_id: @current_user.id)) ? accounts_overview_path : "/accounts"
  end

  def accounts_overview_path
    trading_account = current_user.trading_accounts.active.first
    trading_account.present? ? account_overview_index_path(trading_account.pretty_id) : '/accounts'
  end

  def notice_message
    flash_messages = []

    flash.each do |type, message|
      message = message.first if message.is_a?(Array)
      text = content_tag(:div, message)
      flash_messages << text
    end

    flash_messages.reverse.join("\n").html_safe
  end

  def timeago(time, options = {})
    options[:class] = options[:class].blank? ? "timeago" : [options[:class],"timeago"].join(" ")
    options.merge!(title: time.iso8601)
    tag ||= options[:tag]||:abbr
    content_tag(tag, '', class: options[:class], title: time.iso8601) if time
  end

  def load_asset_file(file)
    if Caishuo::Application.assets.find_asset(file)
      yield file if block_given?
    end
  end

  def controller_javascript_include_tag
    return if @controller_javascript_path == false

    @controller_javascript_path ||= controller_path

    load_asset_file(@controller_javascript_path) do |file| 
      javascript_include_tag  file
    end
  end

  def publisher_opened?(publisher_config)
    publisher_config.fetch(:events).present?
  end

  # 根据邮箱后缀得到邮箱登陆页面
  def email_login_page(email)
    Email::LOGIN_PAGE[email.sub(/^.+@/, "")] || "javascript:void(0);"
  end

  # Flash session fixed
  def uploadify_ajax_feeds_path_with_session_info
    session_key = Rails.application.config.session_options[:key]
    uploadify_ajax_feeds_path(session_key => cookies[session_key], request_forgery_protection_token => form_authenticity_token)
  end

  # /swfupload/fileprogress.js /swfupload/swfupload.queue.js
  def include_swfupload
    str = ""
    str << javascript_include_tag("/swfupload/swfupload.js", "/swfupload/handlers.js", "/swfupload/swfupload.queue.js", "/swfupload/fileprogress.js")
    raw str
  end

  MOBILE_USER_AGENTS =  'palm|blackberry|nokia|phone|midp|mobi|symbian|chtml|ericsson|minimo|' +
    'audiovox|motorola|samsung|telit|upg1|windows ce|ucweb|astel|plucker|' +
    'x320|x240|j2me|sgh|portable|sprint|docomo|kddi|softbank|android|mmp|' +
    'pdxgw|netfront|xiino|vodafone|portalmmm|sagem|mot-|sie-|ipod|up\\.b|' +
    'webos|amoi|novarra|cdm|alcatel|pocket|iphone|mobileexplorer|mobile'
  
  def mobile?
    agent_str = request.user_agent.to_s.downcase
    return false if agent_str =~ /ipad/
    agent_str =~ Regexp.new(MOBILE_USER_AGENTS)
  end

  def hide_mobile(mobile)
    mobile[3, 4] = "****"
    mobile
  end

  def default_email_sender
    (Mail::Encodings.b_value_encode Setting.email_sender, 'UTF-8').to_s  + '<from@sendcloud.com>'  
  end

  def email_notice_popup?
    user_signed_in? && !current_user.confirmed? && request.path != '/account/profile' 
  end

  def can_render_realtime_market_quotes?(controller_name, action_name)
    rejected_controller_action_names = [["baskets", "index"]]
    rejected_controller_action_names.select{|con_name, ac_name| con_name == controller_name && ac_name == action_name }.blank?
  end

  # 微信二维码分享
  def wechat_qr_code(image_width = 140)
    wechat_qr_code_by_url(request.url, image_width)
  end

  def wechat_qr_code_by_url(url, image_width = 140)
    "//cdn.caishuo.com/img/qr_#{image_width}.gif?msg=" + URI.encode(url)
  end

  def humanlize_number(number, precision = 2)
    return "--" if number=="--" or number.blank?
    if number.to_f > 1000000000000
      return number_to_currency(number.to_f/1000000000000, unit: '', precision: precision, format: "%u%n").to_s + "万亿"
    elsif number.to_f > 100000000
      return number_to_currency(number.to_f/100000000, unit: '', precision: precision, format: "%u%n").to_s + "亿"
    elsif number.to_f > 10000
      return number_to_currency(number.to_f/10000, unit: '', precision: precision, format: "%u%n").to_s + "万"
    else
      return number_to_currency(number, unit: '', precision: precision, format: "%u%n")
    end
  end

  def humanlize_number_with_flag(number)
    number >= 0 ? ("+"+humanlize_number(number)) : ('-'+humanlize_number(number.abs)) rescue '--'
  end

  def humanlize_capitalization(capitalization)
    humanlize_number(capitalization)
  end

  # 返回格式 ￥105.87万
  # include_blank 是否包含空格
  def number_to_cash(number, opts = {})
    return number_to_currency(number, opts.merge(format:"%u%n")) if number.abs < 10000
    
    cash = number_to_human(number, opts.reverse_merge(units: {wan: '万', yi: '亿'}, precision: 2))
    cash.gsub!(/ /, '') unless opts[:include_blank]
    
    return cash unless opts.key?(:unit)
    
    insert_pos = cash =~ /^(\+|\-)/ ? 1 : 0
    cash.insert(insert_pos, opts[:unit]) 

    cash.gsub('万', '<em>万</em>').gsub('亿', '<em>亿</em>').html_safe
  end

  # 根据股票显示开盘情况，当地时间
  def market_status(stock)
    market_area = stock.market_area
    exchange = Exchange::Base.by_area(stock.market_area)
    return nil if exchange.blank?
    status = stock.market_status
    # current_time = exchange.workday? && exchange.market_close? ? exchange.close_datatime_str : market_time(market_area)
    "#{status} #{stock.trade_time_str} (#{market_time_desc(market_area)})".html_safe
  end

  def market_time(market_area)
    Exchange::Base.by_area(market_area).now.strftime("%Y-%m-%d %H:%M:%S")
  end

  def market_time_desc(market_area)
    case market_area.try(:to_sym)
    when :us then
      "美东时间"
    else
      "北京时间"
    end
  end

  def us_latest_close_market_time
    Exchange::Us.instance.latest_close_market_time.to_s_full
  end

  def us_next_close_market_time
    Exchange::Us.instance.next_close_market_time.to_s_full
  end

  def hk_latest_close_market_time
    Exchange::Hk.instance.latest_close_market_time.to_s_full
  end

  def hk_next_close_market_time
    Exchange::Hk.instance.next_close_market_time.to_s_full
  end

  def refer_time(from_time)
    str = distance_of_time_in_words(from_time, Time.now, true)
    str << 'ago'.t
    str
  end

  def top_menu_tab_class(tab, current_tab)
    (current_tab and (current_tab == tab)) ? 'active' : nil
  end

  def sub_menu_tab_class(tab, current_tab)
    (current_tab and (current_tab == tab)) ? 'active' : nil
  end

  def add_class_if_include(class_name, *menu_action)
    menu_action.include?(action_name) ? class_name : nil
  end

  def about_menu_class(*menu_action)
    add_class_if_include("active", *menu_action)
  end

  # 用户链接
  # user 用户
  # opts[:inner] 显示文字或头像
  # opts[:class] 指定class
  # opts[:card] true, 开启mini profile, false 关闭 mini profile
  # opts[:url] 指定跳转url，如果为空，则置为profile页地址
  # Demo:
  # link_to_user(user)
  # link_to_user(user, inner: "查看Ta的资料", class: "basket_user", card: true)
  def link_to_user(user, opts = {})
    return if user.blank?
    inner = opts.delete(:inner).try(:html_safe)
    opts[:title] ||= "#{user.username}, #{user.headline}"

    if opts.delete(:card)
      opts.merge!({data: {uid: user.id}})
      opts[:class] = opts[:class].to_s + ' j_bop'
    end

    raw(link_to inner||user.username, opts.delete(:url) || "/p/#{user.id}", opts)
  end

  # 股票链接
  def link_to_stock(stock, opts = {})
    return if stock.blank?
    
    raw(link_to opts.delete(:inner) || stock.symbol, stock_path(stock), opts.reverse_merge(title: stock.symbol))
  end

  # 举报用户
  def link_to_report_abuse_user(user)
    raw(link_to '举报', 'javascript:', class: 'abuse', 'data-uid' => user.id, 'data-username' => user.username )
  end

  def pretty_number_to_currency(value, options={})
    return "--" if value.blank?
    options[:strip_insignificant_zeros] = true
    number_to_currency(value, options)
  end

  # 显示顶部三大股指 
  # index, change, percent, need_margin
  def markets_time_infos
    infos = {timestamp: Time.now.to_i}
    ["cn", "hk", "us"].each do |area|
      infos[area] = Exchange::Base.by_area(area.to_sym).two_days_trading_status
    end
    infos
  end

  # options 接收的keys:
  # prefix ：前缀，默认nil
  # postfix ：后缀，默认nil
  # operator ：是否添加 + -符号，默认true
  # currency_format ：是否对value做货币千分位处理，默认false
  # force_precision : integer，强制几位小数
  # class_value: 以class_value作为em class(plus,mins)参考值，默认nil
  # with_arrow: 箭头，默认false
  def up_down_value(value, options = {})
    options.reverse_merge!({operator: true, currency_format: false, with_arrow: false}).symbolize_keys!
    if value.blank?
      return options[:without_em].present? ? "".html_safe  : "--".html_safe 
    end
    html = ''
    html += value>=0 ? "+" : "-" if options[:operator]
    html += options[:prefix].to_s
    if options[:currency_format]
      html += number_to_currency(value.abs.round(2), unit: '').to_s.strip
    else
      html += options[:force_precision].present? ? format_number(value.abs, options[:force_precision].to_i) : value.abs.round(2).to_s
    end
    html += options[:postfix].to_s
    html.html_safe
  end


  # options 接收的keys:
  # prefix ：前缀，默认nil
  # postfix ：后缀，默认nil
  # operator ：是否添加 + -符号，默认true
  # currency_format ：是否对value做货币千分位处理，默认false
  # force_precision : integer，强制几位小数
  # class_value: 以class_value作为em class(plus,mins)参考值，默认nil
  # without_em: 当value为空时，是否返回em，false返回，true不返回
  # with_arrow: 箭头，默认false
  def up_down_style(value, options = {})
    options.reverse_merge!({operator: true, currency_format: false, with_arrow: false}).symbolize_keys!
    if value.blank?
      return options[:without_em].present? ? "".html_safe  : "<em>--</em>".html_safe 
    end
    html = "<em class='"
    html += (options[:class_value].present? ? options[:class_value].to_f >= 0 : value>=0) ? "plus" : "mins"
    html += options[:with_arrow] ? " ico" : ""
    html += "'>"
    html += value>=0 ? "+" : "-" if options[:operator]
    html += options[:prefix].to_s
    if options[:currency_format]
      html += number_to_currency(value.abs.round(2), unit: '').to_s.strip
    else
      html += options[:force_precision].present? ? format_number(value.abs, options[:force_precision].to_i) : value.abs.round(2).to_s
    end
    html += options[:postfix].to_s + "</em>"
    html.html_safe
  end

  def currency_money(value, unit = "")
    number_to_currency(value, unit: unit, format: "%u%n", strip_insignificant_zeros: false)
  end

  def stock_change_percent_style(stock, opts)
    if stock.realtime_price == 0
      "<em>--</em>".html_safe
    else
      up_down_style(stock.change_percent, opts)
    end
  end

  def stock_change_percent_style_v2(change_percent, price, opts)
    if price == 0
      "<em>--</em>".html_safe
    else
      up_down_style(change_percent, opts)
    end
  end

  def up_or_down_class(value)
    return if value.blank?
    value >= 0 ? "plus" : "mins"
  end

  # 增加0时灰色状态（无class），新增加，部分页面有此状态
  def up_down_class(value)
    return nil if value.blank? || value.zero?
    value > 0 ? "plus" : "mins"
  end

  # StockShow页面使用
  def relative_up_or_down_class(old_price, new_price)
    new_price >= old_price.to_d ? "plus" : "mins"
  end

  def up_or_down_style_with_arrow(value, postfix = nil, added_class = "sico")
    return "<em>--</em>".html_safe if value.blank?
    html = "<em class='" + added_class
    html += value >= 0 ? " plus" : " mins"
    html += "'>"
    html += format_number(value.abs) + postfix.to_s + "</em>"
    html.html_safe
  end
  
  def pricerate_change(stock)
    html = "<em class='"
    html += stock.change_percent > 0 ? "plus" : "mins"
    html += "'>"
    html += stock.realtime_price_with_unit
    html += "<span>"
    html += number_with_operator(stock.change_from_previous_close)
    html += " ( "
    html += number_with_operator(stock.change_percent) + "%"
    html += " )</span></em>"
    html.html_safe
  end

  def to_js_timestamp(time)
    (time + 8.hours).to_i * 1000
  end

  # 当地时间矫正到utc同样时间，用于chart
  def stock_start_trade_timestamp(area)
    time = Exchange::Base.by_area(area).prev_latest_market_day_start_trade_time
    (time.to_i + time.utc_offset) * 1000
  end

  def stock_end_trade_timestamp(area)
    time = Exchange::Base.by_area(area).prev_latest_market_day_end_trade_time
    (time.to_i + time.utc_offset) * 1000
  end

  # utc，今日或下一交易日
  def stock_start_trade_timestamp_of_utc(area)
    Exchange::Base.by_area(area).latest_market_day_start_trade_time.to_i * 1000
  end

  # utc
  def stock_end_trade_timestamp_of_utc(area)
    Exchange::Base.by_area(area).latest_market_day_end_trade_time.to_i * 1000
  end

  def format_number(number, precision = 2)
    format("%.#{precision}f", number.to_f.round(precision))
  end
  
  def number_with_operator(value, precision = 2)
    formated_num = format_number(value.abs, precision)
    value >= 0 ? "+#{formated_num}" : "-#{formated_num}"
  end
  
  def stock_ratestar_width(score)
    score*100/5 rescue 0
  end

  def seo_title(title, hide_page_title_postfix = false)
    title ||= ""
    title << " - 财说，最好用的全球股票交易平台" unless current_page?('/') || hide_page_title_postfix
    content_tag(:title, localize(title))
  end

  def localize(str)
    return str if I18n.locale.to_s == "zh-CN"
    Caishuo::Utils::Translate.convert(I18n.locale.downcase, str)
  end

  def html_to_text(content, length=10000)
    Textable::Base.truncate_long_content(content, length)
  end
  
  def topic_market_index(market, data = {}, need_span = false)
    market_data = data[market] || {}
    return "<em>--</em>".html_safe if market_data.blank?
    pre_html = "<em class='"
    pre_html += market_data[:change].to_f >= 0 ? "plus" : "mins"
    pre_html += "'>"
    if need_span
      pre_html += "<span>#{market_data[:index]}</span>"
    else
      pre_html += market_data[:index]
    end
    html = <<-HTML
        #{pre_html}
          #{market_data[:change].to_f >= 0 ? "+" : nil}#{market_data[:change]}
          #{market_data[:change].to_f >= 0 ? "+" : nil}#{market_data[:percent]}%
        </em>
      HTML
    html.html_safe
  end

  # 取上一交易日的 多少天前，再往前查找最近交易日
  def timestamp_for_chart(area, days_ago)
    prev_workday = ClosedDay.get_work_day(Date.today - 1, area)
    date = ClosedDay.get_work_day(prev_workday - days_ago, area)
    to_js_timestamp(date.to_time)
  end

  # 52周最高最低示意线，当前价格在其中的位置
  def left_px_at_year_price(high, low, current)
    (current - low) * 112 / (high - low)
  end

  # 根据单位把数值转换为usd
  def to_usd_value(value, current_unit)
    currency = BaseStock::CURRENCY_UNITS.invert[current_unit.to_s] || 'usd'
    usd_rate = Currency.transform(currency, 'usd')
    usd_rate * value.to_f
  end

  def show_analytics?
    return false if @hide_baidu
    Rails.env.production? and request.user_agent.present? and !(/NetworkBench/.match(request.user_agent))
  end

  def login_popup_class
    user_signed_in? ? nil : "j-login-popup"
  end

  def to_chinese_unit(value)
    if value.to_f > 10000
      num = (value.to_f/10000).round(2)
      return "#{num}万"
    else
      value.to_f.round(2)
    end
  end

  def download_qrcode_img_by(channel)
    "https://cdn.caishuo.com/img/qr_150.gif?msg=http://#{Setting.mobile_domain}/downloads/redirect?channel=#{channel}"
  end

  # 大数据量stock查询，数据转换时使用已查询好汇率
  def value_to_usd(value, usd_rate)
    usd_rate * value.to_f rescue 0
  end

  def cdn_file(file_full_name)
    "#{Setting.cdn_host}#{file_full_name}"
  end
end
