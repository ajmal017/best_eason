class ArticleStock < ActiveRecord::Base
  belongs_to :article
  belongs_to :stock, class_name: :BaseStock

  validates :article_id, uniqueness: {scope: :stock_id}
end
