class TopicArticle < ActiveRecord::Base
  belongs_to :topic
  belongs_to :article

  scope :visible, ->{ where(visible: true) }
end