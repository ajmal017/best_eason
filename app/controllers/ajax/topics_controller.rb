class Ajax::TopicsController < Ajax::ApplicationController
  before_action :find_topic

  def incre_view
    @topic.increment!(:views_count)
    render :nothing => true
  end

  def chart
    chart_datas = @topic.chart_datas
    render json: {datas: chart_datas}
  end

  private
  def find_topic
    @topic = Topic.find(params[:id])
  end
end