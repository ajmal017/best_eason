class Admin::TopicStocksController < Admin::ApplicationController
  before_action :set_topic
  before_action :set_topic_stock, only: [:update, :destroy]

  def update
    status = @topic_stock.update(topic_stock_params)
    render json: {status: status}
  end

  def destroy
    @topic_stock.destroy
    render json: {status: @topic_stock.destroyed?}
  end

  private
  def set_topic
    @topic = Topic.find(params[:topic_id])
  end
  
  def set_topic_stock
    @topic_stock = @topic.topic_stocks.find(params[:id])
  end

  def topic_stock_params
    params.permit(:notes, :visible)
  end
end
