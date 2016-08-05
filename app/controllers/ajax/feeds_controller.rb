class Ajax::FeedsController < Ajax::ApplicationController
  def like
    @like = Like.create(user_id: current_user.id, feed_id: params[:id])
  end

  def favorite
    @favorite = Favorite.create(user_id: current_user.id, feed_id: params[:id])
  end

  def comment
    @comment = FeedComment.add(current_user.id, params[:feed_comment][:origin_id], nil, params[:feed_comment][:content])
  end

  def comments
    @comments = Feed.find(params[:id]).comments
  end

  def create
    @feed = FeedStatus.add(current_user.id, params[:feed_status][:content])
  end

  def uploadify
    upload_status = Upload::Status.new(image: params[:image], user_id: current_user.try(:id))
    upload_status.save
    render json: upload_status.to_upload
  end
end
