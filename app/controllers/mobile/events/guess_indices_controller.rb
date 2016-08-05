class Mobile::Events::GuessIndicesController < Mobile::ApplicationController
  layout "mobile/common"

  def index
    @prev_index = GuessIndex.prev_index.round(2)
    @guessed = GuessIndex.guessed?(current_user)
  end

  def create
    if current_user
      result = GuessIndex.set(current_user, params[:market_index])
    else
      result = {status: false, login: false}
    end
    render json: result
  end

  def charts
    if current_user
      result = GuessIndex.chart_datas_with_user(current_user.id)
    else
      result = {login: false}
    end
    render json: result
  end
end