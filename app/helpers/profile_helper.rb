module ProfileHelper
  def flag_class(stock)
    html = ""
    html += "class='t-flag "
    html += stock.is_sehk? ? "hk" : "us"
    html += "'"
    html.html_safe
  end
  
  def following_or_followed(current_user, user, more_class = nil)
    if user.friend?(current_user.try(:id))
      ("<div class='w_btn btn_attend_b_cancel btn_dropDown #{more_class}' href='javascript:void(0)'>互相关注<a href='javascript:' class='j_follow' user-id='#{user.id}' action-value='cancel' style='display: none;'>取消关注</a></div>").html_safe
    elsif user.followed_by?(current_user)
      ("<div class='w_btn btn_attend_c btn_dropDown #{more_class}'>已关注<a href='javascript:' class='j_follow' user-id='#{user.id}' action-value='cancel' style='display: none;'>取消关注</a></div>").html_safe
    # elsif current_user && current_user.followed_by?(user)
    #   ("<a class='b_btn btn_attend_b float-right j_follow' user-id='#{user.id}' action-value='focus' href='javascript:void(0)'>关注</a>").html_safe
    elsif user_signed_in?
      ("<a class='b_btn btn_attend_a #{more_class} j_follow' user-id='#{user.id}' action-value='focus' href='javascript:void(0)'>关注</a>").html_safe
    else
      ("<a class='b_btn btn_attend_a #{more_class} j-login-popup' user-id='#{user.id}' action-value='focus' href='javascript:void(0)'>关注</a>").html_safe
    end
  end
  
  def following_or_followed_button(current_user, user)
    if user.followed_by?(current_user)
      "<button class='w_btn btn_attend_cancel j_follow' action-value='cancel' href='javascript:'>取消关注</button>".html_safe
    else
      "<button class='b_btn btn_attend j_follow #{login_popup_class}' action-value='focus' href='javascript:'>关注</button>".html_safe
    end
  end
  
  def nickname(user)
    user.profile.try(:nickname) || "<b>昵称未填</b>".html_safe
  end
  
  def sex(user)
    user.profile.try(:sex) || "<b>性别未填</b>".html_safe
  end
  
  def location(user)
    user.profile.try(:location) || "<b>所在地未填</b>".html_safe
  end
  
  def who_am_i(user)
    user.profile.try(:headline) || "<b>我是谁未填</b>".html_safe
  end
  
  def desc(user)
    user.profile.try(:intro) || "<b>简介未填</b>".html_safe
  end
  
  def orientation(user)
    user.profile.try(:orientation).present? ? user.profile.try(:orientation) : "<b>投资方向未填</b>".html_safe
  end
  
  def concern(user)
    user.profile.try(:concern).present? ? user.profile.try(:concern) : "<b>投资时最关注未填</b>".html_safe
  end
  
  def duration(user)
    user.profile.try(:period) || "<b>一般持仓时间未填</b>".html_safe
  end
end
