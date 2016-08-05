class MD::Feed::Friend < MD::Feed

  def set_data(attrs={})
    self.items.push(new_items)
  end

  def friend_ids
    items.map(&:id) || []
  end

  def title
    I18n.t("feeds.#{feed_type}", num: friend_ids.size)
  end

  def content
    MD::User.in(_id: friend_ids).pluck(:username).map{|name| "@#{name} "} * "、"
    # "@张三丰, @哈哈, @张三丰, @哈哈"
  end
  
  def new_items
    MD::ItemFriend.new(id: source.followable_id, name: source.followable.try(:username), type: :user)
  end

end
