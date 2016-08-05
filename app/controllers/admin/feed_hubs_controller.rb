class Admin::FeedHubsController < Admin::ApplicationController
  before_action :find_feed_hub

  def edit
    @page_title = "修改feed_hub"
  end

  def update
    @feed_hub.update(feed_hub_params)
    redirect_to edit_admin_feed_hub_path(@feed_hub), notice: "修改成功！"
  end

  private
  def find_feed_hub
    @feed_hub = ::MD::FeedHub.find(params[:id])
  end

  def feed_hub_params
    params.require(:feed_hub).permit(:title, :expired_at, :weight, time_rule: [])
  end
end