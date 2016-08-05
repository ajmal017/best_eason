class Mobile::Events::GuessStocksController < Mobile::ApplicationController
  layout "mobile/common"

  def index
    @page_title = "万圣抓妖股"
    @guess_date = MD::Event::GuessStock.now_date
    @is_finished = @guess_date > Date.parse("2015-11-05")
    @guessed = MD::Event::GuessStock.guessed?(current_user.try(:id), @guess_date)
    @joined = MD::Event::GuessStock.joined?(current_user.try(:id))
    @user_guesses = MD::Event::GuessStock.user_guesses(current_user.id) if current_user
    @results = MD::Event::GuessStock.win_results
  end

  def create
    stock = BaseStock.find_by(symbol: params[:symbol])
    MD::Event::GuessStock.add(current_user, stock)
    render json: {}
  end

end