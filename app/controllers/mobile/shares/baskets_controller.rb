class Mobile::Shares::BasketsController < Mobile::ApplicationController
  layout false
  def show
    redirect_to mobile_link "/baskets/#{params[:id]}"
  end

  def graph
    show_data

    begin_date = @basket.start_date
    market_data = @basket.market_indices_by_date(begin_date)
    basket_data = @basket.real_indices_for_chart_cached(begin_date)
    @data = {market: market_data, basket: basket_data}

    render 'show'
  end

  def info
    @basket = Basket.find(params[:id])
    @page_title = '投资理念'
  end

  def content
    show_data
    render 'show'
  end
  
  private
  def show_data
    @basket = Basket.find(params[:id])
    @tags = @basket.tags.map(&:name).unshift(@basket.market_name)
    @page_title = @basket.mobile_page_title
    logs = @basket.adjust_logs.first.try(:basket_adjust_logs)||[]
    @logs_hash = Hash[logs.map{|log| [log.stock_id, log.action] }]
    @weights_hash = Hash[@basket.basket_stocks.map{|bs| [bs.stock_id, bs.weight_percent] }]
    @stocks = BaseStock.where(id: @basket.basket_stocks.map(&:stock_id)+@logs_hash.keys)
    @groups = @stocks.inject(Hash.new { |hash, key| hash[key] = { num: 0, color: nil, stocks:[] } }) do |hash, stock|
      hash[stock.try(:sector_name)][:num] += @weights_hash[stock.id].to_f
      hash[stock.try(:sector_name)][:color]||= stock.try(:sector_color)
      hash[stock.try(:sector_name)][:stocks]<<stock
      hash
    end
    if @basket.cash_weight > 0
      @groups[Sector::C_MAPPING["0"]][:num] = @basket.cash_weight_percent
      @groups[Sector::C_MAPPING["0"]][:color] = Sector::COLORS["0"]
    end
  end

  
end