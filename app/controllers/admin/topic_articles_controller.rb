class Admin::TopicArticlesController < Admin::ApplicationController
  before_action :set_topic
  before_action :set_topic_article, only: [:update]

  def update
    status = @topic_article.update(topic_article_params)
    render json: {status: status}
  end

  private
  def set_topic
    @topic = Topic.find(params[:topic_id])
  end
  
  def set_topic_article
    @topic_article = @topic.topic_articles.find(params[:id])
  end

  def topic_article_params
    params.permit(:visible)
  end
end
