class Notification::Like < Notification::Base
  include Countable

  delegate :commentable, to: :mentionable

  validates :triggered_user_id, presence: true
  
  belongs_to :targetable, polymorphic: true

  def gen_content
    self.content = self.originable.try(:content)
  end
  
  # 设置目标链接对象
  before_save :set_targetable, if: "self.targetable.blank?"
  def set_targetable
    self.targetable = mentionable.top_commentable if mentionable.is_a?(Comment)
  end

  # 评论与赞的区别是增加key:voteme
  def as_json
    {
      id:id,
      topicid: originable_id,
      userid: triggered_user_id,
      username: triggered_user.username,
      desc: triggered_user.headline,
      avator: triggered_user.avatar_url(:normal),
      message: false,
      block: block,
      date: created_at.try(:to_s, :short) + "|" + created_at.try(:iso8601),
      fromname: targetable_human_name, 
      fromtitle: targetable_title,
      fromlink: targetable_link_url,
      unread: format_boolean(!read),
      ischat: format_boolean(is_chat?),
      iserased: format_boolean(iserased?),
      voteme: 1
    }
  end

  def format_boolean(value)
    value ? 1 : 0
  end

  def is_chat?
    mentionable.is_a?(Comment) ? true : false
  end

  def iserased?
    return false unless mentionable.is_a?(Comment)

    mentionable.deleted?
  end

  private
  def block
    return nil unless mentionable.is_a?(Comment)
    %(<a target='_blank' class='j_bop' data-uid='#{user_id}' href='/p/#{user_id}'>#{user.username}: </a>#{mentionable.content})
  end
end
