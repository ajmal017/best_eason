module MobileHelper

  def basket_return_at_mobile_list_page(basket, order_param)
    return_field = Basket::SEARCH_ORDER_MOBILE_RETURN_NAME_MAP.keys.include?(order_param) ? Basket::SEARCH_ORDER_FIELD_MAP[order_param] : "one_month_return"
    return_value = basket.public_send(return_field)
    html = "<span class='circle #{up_or_down_class(return_value)}'>#{up_down_style(return_value, postfix: '%', operator: false)}#{Basket::SEARCH_ORDER_MOBILE_RETURN_NAME_MAP.fetch(order_param, "总收益")}</span>"
    html.html_safe
  end

end