module HomeHelper
  def year_return(value)
    value = value.blank? ? 0 : value.truncate(3)
    if value >= 0
      raw "<span class='return'>1年回报</span><span>" + image_tag('/images/icon_up.png') + "</span><span class='red-percentage'>#{value.round(2)}%</span>"
    else
      raw "<span class='return'>1年回报</span><span>" + image_tag('/images/icon_down.png') + "</span><span class='green-percentage'>#{value.abs.round(2)}%</span>"
    end
  end
end
