class Admin::HotStocksController < Admin::ApplicationController
  def index
    @page_title = "热门股票"
    @hot_stocks = HotStock.all
  end

  def update_all
    params[:hot_stock].each do |p|
      HotStock.new(p).save
    end
    redirect_to "/admin/hot_stocks"
  end

  def edit_all
    @page_title = "修改热门股票"
    @hot_stocks = HotStock.all
  end

end
