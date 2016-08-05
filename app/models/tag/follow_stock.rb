class Tag::FollowStock < Tag::Base
  validates :user_id, presence: true
  validates :name, custom_length: {max: 16, message: "长度不合法"}

  scope :sort, -> { order("sort, id") }
  before_create :set_sort

  def self.add(name, user)
    user.follow_stock_tags.find_or_create_by(name: name.strip)
  end

  def destroy_with(delete_follows = false)
    ActiveRecord::Base.transaction do
      self.taggings.map{|t| t.taggable.destroy } if delete_follows
      self.destroy
    end
  end

  def add_follows(ids)
    follows = Follow::Stock.by_user(self.user_id).where(id: ids)
    follows.map{|follow| self.add_follow(follow) }
  end

  def add_follow(follow)
    self.taggings.create(taggable: follow)
  end

  # 需返回排好序的
  def self.group_info(user)
    self.includes(:taggings).where(user_id: user.id).sort
        .map{|t| {id: t.id, name: t.name, child: t.taggings.map{|x| x.taggable_id}.compact}}
  end

  def self.update_sort(user, ids)
    valid_ids = user.follow_stock_tags.where(id: ids).map(&:id)
    attrs_arr = []
    ids.map{|id| id.to_i}.each_with_index do |id, index|
      attrs_arr << [id, index + 1] if valid_ids.include?(id)
    end
    ImportProxy.import(Tag::Base, %w(id sort), attrs_arr, validate: false, on_duplicate_key_update: [:sort])
  end

  private
  def set_sort
    self.sort = Time.now.to_i if self.sort.blank?
  end
end