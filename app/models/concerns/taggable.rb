module Taggable
  extend ActiveSupport::Concern

  included do
    has_many :taggings, as: :taggable, class_name: 'Tagging', dependent: :destroy
    has_many :tags, -> { uniq },  through: :taggings, source: :tag
  end

  def delete_taggings_by(tag_id)
  	self.taggings.by_tag_id(tag_id).delete_all
  end
end