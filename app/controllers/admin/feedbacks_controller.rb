class Admin::FeedbacksController < Admin::ApplicationController
  def index
    @page_title = "反馈列表"
    params[:feed_type] ||= 0
    @feedbacks = Feedback.where(feed_type: params[:feed_type]).order(updated_at: :desc).paginate(page: params[:page] || 1, per_page: 10).to_a
  end
end