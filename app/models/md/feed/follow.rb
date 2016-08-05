class MD::Feed::Follow < MD::Feed
  NAME_FIELDS = {
    stock: :com_name,
    basket: :title
  }

  def set_data(attrs={})
    self.items.push(new_items)
  end
  
  def title
    I18n.t("feeds.#{feed_type}", num: items.size)
  end

  def new_items
    type = feed_type.to_s.gsub("_follow", '')
    klass = "MD::Item#{type.capitalize}".constantize
    followable = source.followable.reload
    klass.new(id: followable.id, name: followable.send(NAME_FIELDS[type.to_sym]), type: type, ext_data: followable.try(:ext_data_for_feed))
  end


end