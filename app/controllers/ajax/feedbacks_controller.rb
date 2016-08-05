class Ajax::FeedbacksController < Ajax::ApplicationController

  def create
    Feedback.create(feedback_params)
    render json: {status: true}
  end

  def report_user
    extra_params = {feed_type: Feedback.feed_types[:report], reportable_type: :User}
    @feedback = Feedback.find_or_initialize_by(feedback_params.merge(extra_params))
    @feedback.update(updated_at: Time.now)
    render json: {status: true}
  end

  private

  def feedback_params
    params.require(:feedback).permit(:content, :contact_way, :reportable_id).merge(user_id: current_user.try(:id))
  end
end