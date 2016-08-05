module Events::ShipanHelper
  def rank_no_by(page, index)
    (page.to_i-1)*20 + index + 1
  end

  def rank_change_class(rank_change)
    return nil unless rank_change

    if rank_change>0
      "ranking up"
    elsif rank_change<0
      "ranking down"
    else
      "ranking"
    end
  end

  def rank_change_class_2(rank_change)
    return nil unless rank_change

    if rank_change>0
      "plus"
    elsif rank_change<0
      "mins"
    else
      ""
    end
  end

  def shipan_menu_class(menu)
    action_name == menu ? "active" : nil
  end

  def shipan_trade_class(order_detail)
    order_detail.sell? ? "mins" : "plus"
  end

  def shipan_rank_bg_color(index)
    ["#0d71d9", "#954fe6", "#de4a48"][index]
  end

  def shipan_left_days
    interval = (Date.parse("2015-07-16") - Date.today).to_i
    interval >= 0 ? interval : 0
  end
end
