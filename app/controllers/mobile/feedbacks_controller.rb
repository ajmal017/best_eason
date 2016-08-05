class Mobile::FeedbacksController < Mobile::ApplicationController
  protect_from_forgery only: []

  def create
    @feedback = Feedback.create(feedback_params)
    render json: {status: true}
  end

  private
  def feedback_params
    params.require(:feedback).permit(:content, :contact_way)
  end
end