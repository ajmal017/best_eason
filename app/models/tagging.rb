class Tagging < ActiveRecord::Base
  validates :tag_id, presence: true
  validates :taggable_id, presence: true, uniqueness: { scope: [:taggable_type, :tag_id] }
  validates :taggable_type, presence: true

  belongs_to :tag, class_name: 'Tag::Base', counter_cache: true
  belongs_to :taggable, polymorphic: true

  scope :by_tag_id, ->(tag_id) { where(tag_id: tag_id) }
  scope :basket, -> { where(taggable_type: Basket) }

  after_commit on: [:create, :destroy] do
    taggable.touch if basket?
  end

  def basket?
    taggable_type == 'Basket'
  end
end
