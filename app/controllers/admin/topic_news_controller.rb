class Admin::TopicNewsController < Admin::ApplicationController
  before_action :find_topic
  before_action :find_topic_news, only: [:destroy, :update]


  def create
    @topic_news = @topic.topic_news.create(url: params[:url])
  end

  def destroy
    @topic_news.destroy
    render json: {status: @topic_news.destroyed?}
  end

  def update
    @topic_news.update(topic_news_params)
    render json: {status: @topic_news.valid?}
  end

  private
  def find_topic
    @topic = Topic.find(params[:topic_id])
  end

  def find_topic_news
    @topic_news = @topic.topic_news.find(params[:id])
  end

  def topic_news_params
    params.permit(:title, :source)
  end
end