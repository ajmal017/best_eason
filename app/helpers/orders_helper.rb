module OrdersHelper
  def order_status_with_style(status_name)
    if ["执行中"].include?(status_name)
      "<em class='text-blue'>#{status_name}</em>".html_safe
    elsif ["交易取消", "交易失效", "取消中"].include?(status_name)
      "<em class='plus'>#{status_name}</em>".html_safe
    else
      status_name
    end
  end

  def order_action(od)
    style = od.sell? ? 'green' : 'red'
    text = od.sell? ? '卖出' : '买入'
    html = "<td class='"
    html += style
    html += "'>"
    html += text
    html += "</td>"
    html.html_safe
  end

  def order_detail_action(od)
    style = od.sell? ? 'mins' : 'plus'
    text = od.sell? ? '卖出' : '买入'
    html = "<td class='"
    html += style
    html += "'>"
    html += text
    html += "</td>"
    html.html_safe
  end

  def buy_or_sell(trade_type)
    type, cname  = trade_type == "OrderBuy" ? %w[买入 plus] : %w[卖出 mins]
    "<em class=\"#{cname}\">#{type}</em>".html_safe
  end
  
  def order_status(order)
    order_log = order.order_logs.last
    symbol = order_log.try(:base_stock).try(:symbol)
    filled = order_log.try(:total_filled)
    case order.status
    when "confirmed"
      html = "进行中：订单已确认"
    when "cancelling"
      html = "取消中：请稍候"
    when "completed"
      html = "已完成：#{symbol.to_s}已完成#{filled.to_i}股"
    when "cancelled"
      html = "取消中：#{symbol.to_s}已完成#{filled.to_i}股"
    when "expired"
      html = "已过期：订单过期"
    when "error"
      html = "出错了：订单报错"
    end
  end
  
  def order_detail_status(c_status)
    html = ''
    if c_status == '成交'
      html += "<em class='mins'>" + c_status + "</em>"
    elsif c_status == '交易中'
      html += "<em class='light_blue'>" + c_status + "</em>"
    else
      html += "<em class='plus'>" + c_status + "</em>"
    end
    html.html_safe
  end

end
