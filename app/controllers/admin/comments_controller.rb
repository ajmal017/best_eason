class Admin::CommentsController < Admin::ApplicationController
  before_action :get_sender_user, only: [:index]
  def index
    @page_title = "评论列表"
    conds = []
    conds << {content: params[:q]} if params[:q].present?
    conds << {user_id: params[:user_id]} if params[:user_id].present?
    query = {query: {bool: {must: conds.map{ |c| {match: c}}}},:highlight=>{:fields=>{:content=>{}}}}
    if (params[:q] == "" || params[:q] == nil) && params[:user_id] == nil
      query = {query: { match_all: {} }, sort: {created_at: {order: "desc"}}}
    end
    @comments = Comment.__elasticsearch__.search(query).paginate(page: params[:page] || 1, per_page: params[:per_page] || 20)
    @records = @comments.records.load
  end

  def ajax_del_comment
    params[:ids].split(",").each do |id|
      @comment = Comment.find(id)
      @comment.destroy
    end
    render text: "ok"
  end

  def change_deleted
    c = Comment.find(params[:id])
    c.deleted ? c.restore_destroy : c.destroy
    redirect_to :back
  end

  private
    def get_sender_user
      @search_user = User.where(id: params[:user_id]).pluck(:id, :username).flatten
    end
end
