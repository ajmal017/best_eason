class Follow::Stock < Follow::Base
  before_create :set_realtime_price

  def self.followed_stocks_by(user_id)
    self.includes(:followable).by_user(user_id).sort
  end

  def return_from_follow
    ((followable.realtime_price - price)/price).to_f*100
  rescue
    nil
  end

  def tag_stock(tag_id)
    return false if tag_id.blank? || tag_id.to_i.zero?
    tag = self.follower.follow_stock_tags.find_by_id(tag_id)
    tag.add_follow(self) if tag
  end

  def self.update_sort(user, ids)
    valid_ids = self.by_user(user.id).pluck(:id)
    attrs_arr = []
    ids.map(&:to_i).each_with_index do |id, index|
      attrs_arr << [id, index + 1] if valid_ids.include?(id)
    end
    ImportProxy.import(Follow::Base, %w(id sort), attrs_arr, validate: false, on_duplicate_key_update: [:sort])
  end

  private

  def set_realtime_price
    self.price = self.followable.try(:realtime_price)
    self.ori_price = self.price
  end
end