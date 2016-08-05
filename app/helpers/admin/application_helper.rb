module Admin::ApplicationHelper

  # 生成对应角色的操作菜单
  # <div class="panel_title"><a href="javascript:void(0)">系统设置</a></div>
  # <ul class="list"><li><a href="/admin/staffers">管理员</a></li><li><a href="/admin/roles">权限角色</a></li></ul>
  def staffer_menus(staffer)
    return "" unless staffer.present? #&& staffer.allowed?

    html = ""
    Admin::Menu.instance[:menu].each do |m1|
      next unless staffer.admin? || m1["roles"].include?(staffer.role.try(:abbrev))
      html += "<div class='panel_title'><a href='javascript:void(0)'>#{m1["name"]}</a></div>"
      html += "<ul class='list'>"
      m1["menus"].each do |m2|
        html += "<li><a href='#{m2["href"]}' #{"rel='#{m2["rel"]}'" if m2["rel"]} #{"data-confirm='#{m2["data-confirm"]}'" if m2["data-confirm"]} #{"data-method='#{m2["data-method"]}'" if m2["data-method"]}>#{m2["name"]}</a></li>"
      end
      html += "</ul>"
    end
    html.html_safe
  end

  # 菜单
  def admin_menu(title, link_url, is_active = false)
    link_ctl_name = Rails.application.routes.recognize_path(link_url)[:controller]
    is_active = is_active || link_ctl_name.split('/').last == controller_name
    content_tag(:li, class: is_active ? 'active' : '') do 
      content_tag(:a, title, href: link_url)
    end.html_safe
  end

  def notice_tag
    content_tag(:div, flash[:notice], class: 'notice')
  end

  def blank_table(colspan=5)
    raw("<tr><td colspan='#{colspan}'>暂无数据</td></tr>")
  end
  
  def page_info(collections=[])
    render :partial => '/admin/shared/page_info', :locals => { :collections => collections } 
  end
    
  
  def sortable(column, title=nil)
    title ||= controller_name.classify.constantize.human_attribute_name(column)
    css_class = column == sort_column ? "current #{sort_direction}" : nil
    direction = column == sort_column && sort_direction == "asc" ? "desc" : "asc"
    link_to title, {sort: column, direction: direction}, {class: css_class}
  end
  
  def tr_class(index)
    if index%2==0
      "class=success"
    else
      "class=warning"
    end
  end
  
  def qualified_detail_href(qualified, base_stock_id)
    href_text = qualified ? "是" : "否"
    link_to href_text, get_qualified_info_admin_base_stocks_path(base_stock_id: base_stock_id), :remote => true
  end
  
  def qualified_process(base_stock, market_capitalization, average_daily_volume, previous_close)
    return "" if !base_stock.exists?
    str = ""
    str = base_stock.calculable_market_capitalization >= BaseStock::MARKET_CAPITALIZATION_THRESHOLD ? str + "市值#{market_capitalization} >= 250M; " : "市值#{market_capitalization} < 250M; "
    daily_turnover = base_stock.calculable_average_daily_volume * base_stock.realtime_price_with_usd
    str =  daily_turnover >= BaseStock::DAILY_TURNOVER_THRESHOLD ? str + "成交量#{average_daily_volume} * 昨收盘价#{previous_close} = #{daily_turnover} >= 20W" : str + "成交量#{average_daily_volume} * 昨收盘价#{previous_close} = #{daily_turnover} < 20W"
  end
  
  def snapshot_href(base_stock)
    link_to raw("<i class='icon-ok'></i>#{base_stock.symbol}"), get_snapshot_info_admin_base_stocks_path(base_stock_id: base_stock.id), :remote => true
  end
  
  def snapshot_info(snapshot)
    str = ""
    Yahoo::RealTime::FIELDS.map {|f| f.underscore}.each do |field|
      str = str + "<span class='form-title list-show'>#{field}</span>: <span class='form-content'>#{snapshot[field]}</span><br/>"
    end
    raw(str)
  end
end
