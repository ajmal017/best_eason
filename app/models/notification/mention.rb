class Notification::Mention < Notification::Base
  belongs_to :targetable, polymorphic: true

  def gen_content
    self.content = 
    case targetable.class.name
    when "Article"
      targetable.abstract
    when "Basket::Normal"
      targetable.description
    when "Topic"
      targetable.notes
    end
  end

  #============Counter============
  after_create :increment_counter!
  def increment_counter!
    Counter.find_or_create_by(user_id: self.user_id).increment!(:unread_mention_count)
  end
  
  after_destroy :decrement_counter!
  def decrement_counter!
    Counter.find_or_create_by(user_id: self.user_id).decrement!(:unread_mention_count) unless self.read?
  end
   
  def self.adjust_counter!(current_user)
    unread_count = self.where(user_id: current_user.id).unread.count
    Counter.find_or_create_by(user_id: current_user.id).update(unread_mention_count: unread_count)
  end

  def as_json
    {
      id:id,
      topicid: originable_id,
      userid: triggered_user_id,
      username: triggered_user.username,
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
    %(<a target="_blank" class="j_bop" data-uid="#{mentionable.commenter.id}" href="/p/#{mentionable.commenter.id}">#{mentionable.commenter.username}: </a>#{mentionable.content})
  end

end
