class Ajax::FollowStockTagsController < Ajax::ApplicationController
  before_filter :authenticate_user!
  before_action :find_tag, only: [:rename, :delete, :add]
  # all todo modify: responses
  def create
    tag = Tag::FollowStock.add(params[:name], current_user)
    data = {id: tag.id, name: tag.name}
    render json: {status: tag.valid?, data: data, msg: tag.errors.values.flatten.join("; ")}
  end

  def rename
    @tag.update(name: params[:name])
    render json: {status: @tag.valid?, msg: @tag.errors.values.flatten.join("; ")}
  end

  def delete
    delete_follows = [true, "true"].include?(params[:delete_follows])
    @tag.destroy_with(delete_follows)
    render json: {status: @tag.destroyed?}
  end

  # 批量添加到某分组
  def add
    @tag.add_follows(params[:follow_ids])
    render json: {status: true}
  end

  def update_sort
    Tag::FollowStock.update_sort(current_user, params[:tag_ids])
    render json: {status: true}
  end

  private
  def find_tag
    @tag = current_user.follow_stock_tags.find_by_id(params[:id])
  end
end