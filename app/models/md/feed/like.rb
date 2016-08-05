class MD::Feed::Like < MD::Feed
  #feed_types: comment_like 暂时只有一种
  ITEM_TYPE_MAPS = {
    BaseStock: :Stock,
    StaticContent: :News  #todo 如果公告也做评论需要调整此处及feed comment
  }
  
  def set_data(attrs={})
    self.content = source.likeable.text
    push_new_items
  end
  
  def comment
    source.likeable
  end
  
  def push_new_items
    top_type = ITEM_TYPE_MAPS[comment.top_commentable_type.to_sym] || comment.top_commentable_type
    top_klass = "MD::Item#{top_type}".constantize
    name_field = MD::Feed::Comment::NAME_FIELDS[top_type.downcase.to_sym]
    items.push top_klass.new(id: comment.final_top_commentable_id, name: comment.top_commentable.send(name_field), type: top_type.downcase, user_id: feeder.id)
    items.push MD::ItemComment.new(id: comment.id, ext_data: {user_id: comment.user_id, username: comment.user.try(:username), message: comment.body, mobile_message: comment.final_mobile_content}, type: :comment)
  end
end
