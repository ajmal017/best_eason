class Admin::GuessStocksController < Admin::ApplicationController

  def index
  	@dates = ::MD::Event::GuessStock::DATES
    @megs = ::MD::Event::GuessStock.sort.includes(:user)
    @megs = @megs.where(winned: true) if params[:wt] == "winned_true" #获取已获奖用户
    @megs = @megs.where(winned: false) if params[:wf] == "winned_false" #获取未获奖用户
    @megs = @megs.where(date: params[:date].to_date) if !params[:date].nil? #获取不同date的用户
    @megs = @megs.paginate(page: params[:page] || 1, per_page: params[:per_page] || 20)
  end

  def change_winned
  	gs = ::MD::Event::GuessStock.find(params[:id])
  	gs.winned ? gs.update(winned: false) : gs.update(winned: true)
    redirect_to :back
  end

end