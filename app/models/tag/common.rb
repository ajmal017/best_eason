class Tag::Common < Tag::Base
  scope :hot, -> { where(hot: true) }
  
  def add(taggable)
    self.taggings.create(taggable: taggable)
  end
  
  def remove(taggable)
    self.taggings.find_by(taggable: taggable).try(:destroy)
  end

  def be_used?
    Topic.where(tag_id: self.id).first.present?
  end
  
  # 没有校验，只供admin后台功能调用
  def self.update_positions(ids)
    attrs_arr = []
    ids.each_with_index do |id, index|
      attrs_arr << [id.to_i, index + 1]
    end
    Tag::Base.import(%w(id sort), attrs_arr, validate: false, on_duplicate_key_update: [:sort])
  end

  def self.hot_tags_with(tag_id)
    tag = ::Tag::Common.find_by_id(tag_id)
    normal.hot.order(:sort).to_a.unshift(tag).compact.uniq
  end
end