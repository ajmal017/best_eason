module UsersHelper
  
  def display_market_index(market)
    return if market.blank?
    if(market[:change].to_i > 0)
      "<em class='plus'>+#{market[:change]} (#{market[:percent]}%)</em>".html_safe
    else
      "<em class='mins'>#{market[:change]} (#{market[:percent]}%)</em>".html_safe
    end
    
  end
end
