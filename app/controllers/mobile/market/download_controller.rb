# 下载页渠道号判断
class Mobile::Market::DownloadController < Mobile::ApplicationController
  layout "mobile/common"
  before_action :set_ga_label
  before_action :incre_app_channel_views, only: [:index]

  def index
    @hide_top_bar = true
    redirect_to mobile_link(redirect_mobile_downloads_path(channel: params[:channel])) if params[:channel].to_s.downcase == "momo2"
    channel = params[:channel].to_s.downcase
    @click_all = channel.start_with?("momo")
    @show_desc = channel.start_with?("toutiao")
    render_toutiao10 if ["toutiao10", "momo3"].include?(params[:channel]) || channel.start_with?("shenma") || channel.start_with?("zhihuitui") || channel.start_with?("sogou")
  end

  # 弃用：使用 mobile/downloads/redirect
  def redirect
    @apk_url = ChannelCode.download(params[:channel], true)
    redirect_to @apk_url
  end

  private

  def render_toutiao10
    @pic_1, @pic_2, @pic_3 = pic_by_channel
    render :toutiao10 and return
  end

  def pic_by_channel
    if ["toutiao10", "momo3"].include?(params[:channel])
      ['/zt/market/151027/download_1.jpg?a2', '/zt/market/151027/download_2.jpg?b2', '/zt/market/151027/download_3.jpg?c2']
    elsif params[:channel].start_with?("sogou")
      ['/zt/market/151216/download_1.jpg?a2', '/zt/market/151216/download_2.jpg?b2', '/zt/market/151216/download_3.jpg?c2']
    else
      ['/zt/market/151204/download_1.jpg?a2', '/zt/market/151204/download_2.jpg?b2', '/zt/market/151204/download_3.jpg?c2']
    end
  end

end