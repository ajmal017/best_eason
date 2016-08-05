module BasketsHelper
  
  def basket_return_at_list_page(basket, order_param)
    return_field = Basket::SEARCH_ORDER_RETURN_NAME_MAP.keys.include?(order_param) ? Basket::SEARCH_ORDER_FIELD_MAP[order_param] : "one_month_return"
    html = ''
    html += Basket::SEARCH_ORDER_RETURN_NAME_MAP[order_param] || "1月回报"
    if basket.public_send(return_field).nil?
      html += ' -- '
    elsif basket.public_send(return_field).to_f >= 0
      html += ' <em class="plus ico">'
      html += basket.public_send(return_field).to_f.round(2).to_s + '%</em>'
    else
      html += ' <em class="mins ico">'
      html += basket.public_send(return_field).to_f.round(2).abs.to_s + '%</em>'
    end
    html.html_safe
  end
  

  def create_days_for_view(create_days)
    if create_days <= 0
      "今天"
    else
      "#{create_days}天"
    end
  end

  # add basket page
  def stock_return_html(stock_return)
    if stock_return >= 0
      html = '<span class="price-change cs-color-red">' + image_tag("/images/icon_up.png")
    else
      html = '<span class="price-change cs-color-green">' + image_tag("/images/icon_down.png")
    end
    html += stock_return.to_s + '%</span>'
    html.html_safe
  end

  # add/base basket page
  def change_percent_span_for_table(change_percent)
    if change_percent >= 0
      html = "<span class='table-red'>" + image_tag('/images/up.png') + " #{change_percent}%</span>"
    else
      html = "<span class='table-green'>" + image_tag('/images/down.png') + " #{change_percent}%</span>"
    end
    html.html_safe
  end

  def follow_baskets_item_div_style(arr_index)
    (arr_index+1)%3 == 0 ? 'margin-right:0px;' : ''
  end

  def change_percent_span(change_percent, with_brackets = false)
    left_brackets = with_brackets ? "(" : ""
    right_brackets = with_brackets ? ")" : ""
    if change_percent >= 0
      html = "<span class='red'>#{left_brackets}" + image_tag('/images/up.png') + "  #{change_percent}% #{right_brackets}</span>"
    else
      html = "<span class='green'>#{left_brackets}" + image_tag('/images/down.png') + "  #{change_percent}% #{right_brackets}</span>"
    end
    html.html_safe
  end

end