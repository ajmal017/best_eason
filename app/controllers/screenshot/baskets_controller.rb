class Screenshot::BasketsController < Screenshot::BaseController

  def mini_chart
    @bid = params[:id]
  end
end