class Stocks::AnnouncementsController < ApplicationController
  before_action :load_stock, only: [:show]

  def index
  end

  def show
    @announcement = RestClient.api.stock.announcement.find(params[:id])
    @content = RestClient.api.stock.announcement.content(params[:id])
    @page_title = "公告-" + @announcement['info_title']
  end

  private

  def load_stock
    @stock = BaseStock.find(params[:stock_id])
  end
end
