class Admin::ConfigsController < Admin::ApplicationController
  def index
    @page_title = "网站配置"
  end

  def set_unconfirmed_orders_hours
    Configs.set_unconfirmed_orders_hours(params[:hours])
    render :json => {status: 'ok'}
  end
end