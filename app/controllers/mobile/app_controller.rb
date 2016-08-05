class Mobile::AppController < Mobile::ApplicationController
  layout "mobile/common"
  before_action :set_ga_label
  before_action :incre_app_channel_views, only: [:index]

  def index
    @hide_top_bar = true
    @click_all = params[:channel].to_s.downcase.start_with?("momo")
    @link = mobile_link("/mobile/downloads/redirect?channel=#{params[:channel]}&ts=#{Time.now.to_i}")
  end
end
