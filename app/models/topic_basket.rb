class TopicBasket < ActiveRecord::Base
  belongs_to :topic
  belongs_to :basket

  before_create :create_basket_tagging
  before_destroy :delete_basket_tagging

  private
  def create_basket_tagging
    tagging = self.basket.original.taggings.create(tag_id: self.topic.tag_id)
    self.tagged = tagging.valid?
    true
  end

  def delete_basket_tagging
    self.basket.original.taggings.by_tag_id(self.topic.tag_id).delete_all if self.tagged
  end
end