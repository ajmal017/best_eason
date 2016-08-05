module MessagesHelper
  
  def message_talk_title(username)
    params[:from] == "profile" ? "与#{username}对话中" : "查看私信"
  end
  
  def talk_submit_name
    params[:from] == "profile" ? "发送" : "回复"
  end

  def pretty_simple_format(msg)
    simple_format(msg).gsub(/<p>/,'').gsub(/<\/p>/,'<br>').html_safe
  end
end
