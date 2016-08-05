module Commentable
  extend ActiveSupport::Concern
  included do
    #评论
    #has_many :comments, ->{order(created_at: :desc)}, as: :commentable, class_name: 'Comment', dependent: :destroy
    has_many :comments, ->{order(id: :desc)}, as: :top_commentable, class_name: 'Comment', dependent: :destroy
    has_many :commenters, through: :comments, source: :commenter

  end

  def top_comments
    comments.top
  end

  def top_comments_count
    top_comments.count
  end

  def undeleted_comments
    comments.undeleted.sort_desc
  end


  COMMENTED_KLASS = [Article, Basket, Topic, Contest, BaseStock, MD::Data::SpiderNews]
  COMMENTED_KLASS_ALL = [Article, Basket, Topic, Contest, BaseStock, MD::Data::SpiderNews, Comment]
end
