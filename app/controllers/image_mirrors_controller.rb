class ImageMirrorsController < ActionController::Base

  def p2p_product_img
    @stock = BaseStock.find(params[:stock_id])
    @stock_indexs = @stock.close_price_by_date(Date.today-30.days, Date.today).map{ |(n, v)| [n.strftime("%Y-%m-%d"), v.to_f.round(2)] }
    @change_type = params[:change_type]
  end

end
