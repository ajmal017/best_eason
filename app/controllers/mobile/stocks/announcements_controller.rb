class Mobile::Stocks::AnnouncementsController < Mobile::ApplicationController
  layout nil

  before_action :load_stock, only: [:show]

  def index
  end

  def show
    @announcement = RestClient.api.stock.announcement.find(params[:id])
    @content = RestClient.api.stock.announcement.content(params[:id])
    @page_title = "#{@announcement["info_title"]} - 公告"
    render layout: "mobile/common"
  end

  private

  def load_stock
    @stock = BaseStock.find(params[:stock_id])
  end

end
