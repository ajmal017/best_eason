class Ajax::ContestsController < Ajax::ApplicationController
  before_action :find_contest, only: [:comment, :comments, :sign_next]

  def comment
    @comment = @contest.comments.create(comment_params) if user_signed_in?
  end

  def comments
    @comments = @contest.comments.paginate(:page => params[:page]||1, :per_page => Comment::PER_PAGE)
  end

  def sign_next
    @contest.sign_next_contest(current_user.id)
    render json: {status: true}
  end

  private

  def find_contest
    @contest = Contest.find(params[:id])
  end

  def comment_params
    params.require(:comment).permit([:content]).merge(user_id: current_user.try(:id), replyable: @contest)
  end
end