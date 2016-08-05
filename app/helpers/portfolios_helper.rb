module PortfoliosHelper
  def change_percent(value)
    value = 0 if value.blank?
    if value >= 0
      raw "<img src='/images/icon_up.png' /><span class='red-color'>#{value.abs.to_s}%</span>"
    else
      raw "<img src='/images/icon_down.png' /><span class='green-color'>#{value.abs.to_s}%</span>"
    end
  end
  
  def portfolio_return(type, value)
    return_name = case type
              when "month"
                "1月回报"
              when "year"
                "1年回报"
              end
    value = value.blank? ? 0 : value.truncate(3)
    if value >= 0
      raw "<span>#{return_name}</span><span><img src='/images/icon_up.png' /></span><span class='modal-red'>#{value}%</span>"
    else
      raw "<span>#{return_name}</span><span><img src='/images/icon_down.png' /></span><span class='modal-green'>#{value.abs}%</span>"
    end
  end
  
  def stock_price_change(stock)
    change_value = stock.change_percent
    if change_value >= 0
      raw "#{stock.currency_unit} #{stock.realtime_price} <span class='price-change cs-color-red'><img src='/images/icon_up.png' /> #{change_value}%</span>"
    else
      raw "#{stock.currency_unit} #{stock.realtime_price} <span class='price-change cs-color-green'><img src='/images/icon_down.png' /> #{change_value.abs}%</span>"
    end
  end
  
  def stock_month_and_year_return(stock)
    year_return = stock.one_year_return
    month_return = stock.one_month_return
    str = ""
    if month_return >= 0
      str = str + "<span class='price-change cs-color-red'><img src='/images/icon_up.png' /> #{month_return}%</span> "
    else
      str = str + "<span class='price-change cs-color-green'><img src='/images/icon_down.png' /> #{month_return.abs}%</span> "
    end
    
    if year_return >= 0
      str = str + "<span class='price-change cs-color-red'><img src='/images/icon_up.png' /> #{year_return}%</span>"
    else
      str = str + "<span class='price-change cs-color-green'><img src='/images/icon_down.png' /> #{year_return.abs}%</span>"
    end
    raw str
  end
  
  def stock_year_return(stock)
    year_return = stock.one_year_return
    str = ""
    if year_return >= 0
      str = str + "<span class='price-change cs-color-red'><img src='/images/icon_up.png' /> #{year_return}%</span>"
    else
      str = str + "<span class='price-change cs-color-green'><img src='/images/icon_down.png' /> #{year_return.abs}%</span>"
    end
    raw str
  end
  
  def stock_month_return(stock)
    month_return = stock.one_month_return
    str = ""
    if month_return >= 0
      str = str + "<span class='price-change cs-color-red'><img src='/images/icon_up.png' /> #{month_return}%</span> "
    else
      str = str + "<span class='price-change cs-color-green'><img src='/images/icon_down.png' /> #{month_return.abs}%</span> "
    end
    raw str
  end
  
  def special_portfolio_style(index)
    "margin-right:0px;" if index%4 == 3
  end
  
  def pk_header_class(type)
     type == "pk-show" ? "header clearfix" : "header show-header clearfix"
  end
end
