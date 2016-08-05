class Stocks::NewsController < ApplicationController
  before_filter :authenticate_user!, only: [:show]
  before_action :load_stock, only: [:show]

  def index
  end

  def show
    @news = RestClient.api.stock.news.find(params[:id])
  end

  private

  def load_stock
    @stock = BaseStock.find(params[:stock_id])
  end
end
