class Ajax::CommentsController < Ajax::ApplicationController
  before_filter :authenticate_user!, only: [:reply, :like, :destroy]
  before_action :find_comment, :except => []

  def reply
    @reply = Comment.reply(current_user.id, params[:content], @comment)
    
    if @reply.valid?
      result = @reply.json_with(current_user.id)
    else
      result = {status: 1, msg: @reply.format_err_msg}
    end
    render json: result 
  end
  
  def article_reply
    @reply = @comment.comment_by(current_user.id, params[:content]) if user_signed_in?
    respond_to do |format|
      format.js {  }
      format.json { 
        render json: {content: @reply.content, author: @reply.commenter.username, id: @reply.id}
      }
    end
  end

  def like
    like = Like.add(current_user.id, @comment)
    render json: {status: (like.valid? ? 0 : 1), num: @comment.reload.likes_count}
  end

  def delete
    @comment.destroy if @comment.user_id == current_user.id
    topicnum = @comment.root_replyed.present? ? @comment.root_replyed.comments_count : 0
    render json: {status:0, threadnum: @comment.top_commentable.comments_count, topicnum: topicnum}
  end

  def all_replies
    @replies = @comment.replies.sort_desc
  end

  private
  def find_comment
    @comment = Comment.find(params[:id])
  end

  def reply_attrs
    { 
      content: params[:content], user_id: current_user.id, commentable_ids: @comment.child_commentable_ids
    } 
  end
end
