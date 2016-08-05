class CommentsController < ApplicationController
  before_filter :alias_stock_id, :fetch_commentable, only: [:create, :index]

  before_filter :load_comment, only: [:like, :destroy]

  def index
    @comments = @top_commentable.comments.undeleted.includes(:commenter, :root_replyed).paginate(:page => params[:page]||1, :per_page => Comment::PER_PAGE)
    
    respond_to do |format|
      format.html
      format.json do
        render json: { lists: Comment.list_json(@comments, current_user.try(:id)), totalNumber:@comments.total_entries, pages: @comments.total_pages, index: @comments.current_page }
      end
    end
  end

  def create
    @comment = Comment.add(current_user.id, params[:content], @top_commentable)
    
    if @comment.valid?
      result = @comment.json_with(current_user.id)
    else
      result = {status: 1, msg: @comment.format_err_msg }
    end
    render json: result
  end

  def show
    comment = Comment.find(params[:id])
    render json: Comment.talk_json(comment, current_user.try(:id))
  end

  private

  def load_comment
    @comment = Comment.find(params[:id])
  end
  
  def alias_stock_id
    params[:base_stock_id] = params[:stock_id] if params[:stock_id]
  end

  # raise 404
  def fetch_commentable
    target = Commentable::COMMENTED_KLASS.detect{|c| params["#{c.name.underscore}_id"]}
    
    @top_commentable= target.find(params["#{target.name.underscore}_id"])
  end
end
