module StocksHelper
  #todo: delete
  def price(bs)
    currency = bs.exchange == 'SEHK' ? 'HK$' : '$'
    (currency + bs.realtime_price.to_s).html_safe
  end
  
  def price_changed(bs)
    change_class = bs.price_changed >= 0 ? 'rise' : 'fell'
    html = "<em class='#{change_class}'>#{bs.price_changed.round(2)} (#{bs.change_percent}%)</em>"
    html.html_safe
  end
  
  def up_down(value, options = {})
    options.reverse_merge!({operator: true, currency_format: false}).symbolize_keys!
    return "<em>--</em>".html_safe if value.blank?
    html = "<em class='"
    html += value>=0 ? "plus ico" : "mins ico"
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
  
  def stock_info_of(bs)
    change_class = bs.price_changed >= 0 ? 'rise' : 'fell'
    html = "<li><a href='/stocks/#{bs.id}'>"
    html += "<span>#{bs.symbol}</span>"
    html += "<span>"
    html += number_to_currency(bs.realtime_price, unit: bs.currency_unit, format:"%u%n", negative_format: "%u-%n")
    html += "</span>"
    html += "<em class='#{change_class}'>#{bs.change_percent.abs}%</em></a>"
    html += '</li>'
    
    html.html_safe
  end
  
  #todo: delete?
  def sectors
    html = ""
    Sector::MAPPING.each do |code, c_name|
      html += "<a href='javascript:void(0)' data-filter=" + "'#{code}'" + ">" + c_name + "</a>"
    end
    html.html_safe
  end

  def stock_pe_comparison(stock_screener)
    stock_screener_comparison(stock_screener.try(:pe), stock_screener.try(:pe_c), "高", "低", true)
  end

  def stock_pe_desc(stock_screener)
    high_desc = "股票比较昂贵，相对投资价值较小"
    low_desc = "股票比较便宜，相对投资价值较大"
    stock_screener_description(stock_screener.try(:pe), stock_screener.try(:pe_c), high_desc, low_desc)
  end

  def stock_lpg_comparison(stock_screener)
    stock_screener_comparison(stock_screener.try(:lpg), stock_screener.try(:lpg_c), "高", "低")
  end

  def stock_lpg_desc(stock, stock_screener)
    if stock.is_cn?
      high_desc = "企业当年主营业务收入较高，表明市场前景较好"
      low_desc = "企业当年主营业务收入较低，表明市场前景较差"
    else
      high_desc = "华尔街分析师预计公司未来的利润增长较高"
      low_desc = "华尔街分析师预计公司未来的利润增长较低"
    end
    stock_screener_description(stock_screener.try(:lpg), stock_screener.try(:lpg_c), high_desc, low_desc)
  end

  def stock_cf_comparison(stock_screener)
    stock_screener_comparison(stock_screener.try(:cf), stock_screener.try(:cf_c), "强", "弱")
  end

  def stock_cf_desc(stock_screener)
    high_desc = "企业的盈利质量较好，现金流充足"
    low_desc = "企业的盈利质量较差，现金流不足"
    stock_screener_description(stock_screener.try(:cf), stock_screener.try(:cf_c), high_desc, low_desc)
  end

  def stock_gm_comparison(stock_screener)
    stock_screener_comparison(stock_screener.try(:gm), stock_screener.try(:gm_c), "高", "低")
  end

  def stock_gm_desc(stock_screener)
    high_desc = "公司产品附加值较高，赚钱效率较高"
    low_desc = "公司产品附加值较低，赚钱效率较低"
    stock_screener_description(stock_screener.try(:gm), stock_screener.try(:gm_c), high_desc, low_desc)
  end

  def stock_wst_comparison(stock_screener)
    stock_screener_comparison(stock_screener.try(:wst), stock_screener.try(:wst_c), "高", "低")
  end

  def stock_wst_desc(stock_screener)
    high_desc = "较高的上涨空间表示更被华尔街看好"
    low_desc = "较低的上涨空间表示不被华尔街看好"
    stock_screener_description(stock_screener.try(:wst), stock_screener.try(:wst_r), high_desc, low_desc)
  end

  def stock_wst_cn_desc(stock_screener)
    high_desc = "每单位资产盈利能力较高"
    low_desc = "每单位资产盈利能力较低"
    stock_screener_description(stock_screener.try(:wst), stock_screener.try(:wst_c), high_desc, low_desc)
  end

  def stock_div_comparison(stock_screener)
    stock_screener_comparison(stock_screener.try(:div), stock_screener.try(:div_c), "高", "低")
  end

  def stock_div_cn_comparison(stock_screener)
    stock_screener_comparison(stock_screener.try(:div), stock_screener.try(:div_c), "高", "低", true)
  end

  def stock_div_desc(stock_screener)
    high_desc = "较高的现金分红表示公司能给股东较高的现金回报"
    low_desc = "较低的现金分红表示公司能给股东较低的现金回报"
    stock_screener_description(stock_screener.try(:div), stock_screener.try(:div_r), high_desc, low_desc)
  end

  def stock_div_cn_desc(stock_screener)
    high_desc = "每股内含净资产值低，投资价值越低"
    low_desc = "每股内含净资产值高，投资价值越高"
    stock_screener_description(stock_screener.try(:div), stock_screener.try(:div_c), high_desc, low_desc)
  end

  def stock_screener_comparison(self_index, avg_index, high_label, low_label, reverse = false)
    return "--" unless self_index && avg_index
    em_class = (reverse ? (self_index.to_f < avg_index.to_f) : (self_index.to_f >= avg_index.to_f))  ? "plus" : "mins"
    em_label = self_index.to_f >= avg_index.to_f ? high_label : low_label
    "<em class='#{em_class}'>#{em_label}</em>".html_safe
  end

  def stock_screener_data_desc(value, postfix, presicion = nil)
    if presicion
      value.present? ? value.round(presicion).to_s + postfix : "暂无数据"
    else
      value.present? ? value.to_i.to_s + postfix : "暂无数据"
    end
  end

  def stock_screener_description(self_data, avg_data, high_desc, low_desc)
    return "&nbsp;".html_safe unless self_data && avg_data
    self_data.to_f >= avg_data.to_f ? high_desc : low_desc
  end

  def stock_screener_score(score)
    score.present? ? format_number(score, 1) : "--"
  end

  def stock_screener_column_class(self_data, avg_data)
    return nil unless self_data && avg_data
    self_data.to_f >= avg_data.to_f ? "raise" : "down"
  end

  # 格式化买一卖一
  def pretty_bid_offer(value, previous_close, element_id)
    "<em id='#{element_id}' class='#{up_or_down_class(value.to_f-previous_close)}'>#{value.present? ? value : '--'}</em>".html_safe
  end

  # 股数显示：A股按手，其他按股
  def pretty_stock_volume(value, stock)
    volume = stock.is_cn? ? value.to_i/100 : value.to_i
    presicion = volume > 10000 ? 2 : 0
    humanlize_number(volume, presicion)
  end

  def display_market_index_info(index_name, index_symbol, datas = {}, active = false)
    index_datas = datas.with_indifferent_access[index_symbol] || {}
    active_class = active ? "active" : nil

    if Exchange::Base.by_area(BaseStock::MARKET_INDEX_AREAS[index_symbol.to_s]).pre_open?
      return "<a class='gray #{active_class}' href='javascript:;'><span>#{index_name}</span><b>#{index_datas[:index]}</b><b>0.00 0.00%</b></a>".html_safe
    end
    
    class_name =  index_datas[:change].to_f >= 0 ? "plus" : "mins"
    operator = index_datas[:change].to_f >= 0 ? "+" : ""
    html = <<-HTML
      <a class="#{class_name} #{active_class}" href="javascript:;">
        <span>#{index_name}</span>
        <b>#{index_datas[:index]}</b>
        <b>#{operator}#{index_datas[:change]} #{operator}#{index_datas[:percent]}%</b>
      </a>
    HTML
    html.html_safe
  end

  # 长期盈利增长
  def stock_lpg_name(stock)
    stock.is_a?(Stock::Cn) ? "主营业务增长率" : "长期盈利增长"
  end

  # 华尔街目标价格
  def stock_target_price_name(stock)
    stock.is_a?(Stock::Cn) ? "资产回报率" : "华尔街目标价格"
  end

  # 分红
  def stock_bonus_name(stock)
    stock.is_a?(Stock::Cn) ? "市净率" : "现金分红"
  end

  def bid_offer_volume(volume)
    volume >= 10000 ? "#{(volume/10000).to_i}万" : volume
  end

  def stock_trade_type_option_class(trading_account, value)
    classes = ""
    classes += "active" if value=="0"
    classes += "hide " if trading_account.try(:pt?) && value!="0"
    classes
  end

  def stock_category_class(category)
    {"工业" => "industry", "非日常生活消费品" => "consumable", "医疗保健" => "medical", "信息技术" => "technology",
      "公用事业" => "public", "其他" => "others", "日常消费品" => "usual", "金融" => "finance", 
      "能源" => "energy", "原材料" => "material", "现金" => "cash"}[category]
  end
end
