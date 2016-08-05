class MD::Feed::Comment < MD::Feed
  NAME_FIELDS = {
    topic: :title,
    stock: :com_name,
    basket: :title,
    article: :title,
    news: :title,
    contest: :name
  }

  def set_data(attrs={})
    self.content = source.text
    self.data[:html_content] = source.body
    push_new_items
  end
  
  def replyed
    source.direct_replyed
  end

  def push_new_items
    type = feed_type.to_s.gsub("_comment", '')
    klass = "MD::Item#{type.capitalize}".constantize
    name_field = NAME_FIELDS[type.to_sym]
    
    return nil unless name_field
    items.push klass.new(id: source.final_top_commentable_id, name: source.top_commentable.send(name_field), type: type, ext_data: source.top_commentable.try(:ext_data_for_feed))
    items.push MD::ItemComment.new(id: replyed.id, ext_data: {user_id: replyed.user_id, username: replyed.user.try(:username), message: replyed.body, mobile_message: replyed.final_mobile_content}, type: :comment) if replyed
  end
  
  def web_json
    ischat = source.try(:is_chat?) && !source.try(:is_erased?) ? 1 : 0
    super.merge!(ischat: ischat)
  end

end
