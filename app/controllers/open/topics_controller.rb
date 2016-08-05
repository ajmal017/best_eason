class Open::TopicsController < Open::BaseController

  def show
    symbol = Caishuo::Utils::SymbolConverter.to_caishuo(params[:id].to_s)
    data = SymbolTopicMaper.find(symbol)
    render json: {status: 1, data: data}
  end
end