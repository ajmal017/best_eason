class Notification::Comment < Notification::Base
  include Countable
  
  validates :content, presence: true
  validates :triggered_user_id, presence: true

  belongs_to :targetable, polymorphic: true

  def gen_content
    self.content = self.originable.try(:body)
  end

  # 设置目标链接对象
  before_save :set_targetable, if: "self.targetable.blank?"
  def set_targetable
    self.targetable = originable.top_commentable
  end

  def as_json
    {
      id: id,
      topicid: originable_id,
      userid: triggered_user_id,
      username: triggered_user.username,
      desc: triggered_user.headline,
      avator: triggered_user.avatar_url(:normal),
      message: originable.body,
      block: block,
      date: created_at.try(:to_s, :short) + "|" + created_at.try(:iso8601),
      fromname: targetable_human_name, 
      fromtitle: targetable_title,
      fromlink: targetable_link_url,
      unread: format_boolean(!read),
      ischat: format_boolean(is_chat?),
      iserased: format_boolean(iserased?)
    }       
  end

  def format_boolean(value)
    value ? 1 : 0
  end

  # 如果回复的对象是一个评论的话返回TRUE
  def is_chat?
    mentionable.is_a?(Comment) && !mentionable.is_erased? ? true : false
  end

  def iserased?
    return false unless mentionable.is_a?(Comment)

    mentionable.deleted?
  end
  
  private
  
  # 如果mentionable是评论的话,那么mentionable的作者一定是当前用户
  # 如果是一级评论的话，则block返回空字符串
  def block
    return "" unless mentionable.is_a?(Comment)
    # return "" if mentionable.direct_replyed.blank? && mentionable.deleted
    %(<a target="_blank" class="j_bop" data-uid="#{user_id}" href="/p/#{user_id}">#{user.username}: </a>#{mentionable.content})
  end

end
