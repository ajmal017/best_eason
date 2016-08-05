class ArticleComment < ActiveRecord::Base
  belongs_to :article, counter_cache: true

  validates :content, presence: true
end
