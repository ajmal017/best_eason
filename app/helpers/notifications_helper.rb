module NotificationsHelper
  
  def notice_unread_style(notice)
    notice.read? ? '' : 'unread'
  end

  # 评论内容前缀描述
  def comment_desc_prefix(notice)
    if notice.mentionable.is_a?(Basket)
      "评论我的组合" 
    else
      "回复我的评论"
    end
  end

  # 通知中展示被评论的内容
  def notice_commentable_content(notice)
    mentionable = notice.mentionable
    
    case mentionable
    when Basket
      mentionable.title
    when Comment
      mentionable.body
    else
      mentionable.content
    end
  end

end
