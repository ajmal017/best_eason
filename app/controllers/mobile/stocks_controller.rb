class Mobile::StocksController < Mobile::ApplicationController
  layout 'mobile'
  def index
    set_pc_link("/stocks")
    @body_class = "stockListMobile"
    @page_title = "个股投资"
    @market_indexes = ::StockIndex.all
    @search = params.fetch(:search, {}).select{|k,v| v.present? }
    @sort = params[:sort] || {}
    
    @stocks = BaseStock.search_list(@search)
    
    @stocks = @stocks.order(sort_by + " " + direction).paginate(page: params[:page] || 1,  per_page: params[:per_page] || 15)
    data = ->{
      lists = []
      @stocks.each do |stock|
        lists << {name: stock.symbol, 
           symbol: stock.c_name, 
           score: stock.stock_screener.score, 
           price: stock.realtime_price, 
           percent: stock.change_percent.round(2), 
           link: mobile_link("/mobile/stocks/#{stock.id}")}
      end
      lists
    }
    
    respond_to do |format|
      format.html
      format.json {render :json => {:lists => data.call, nextPage: @stocks.next_page.blank? ? 0 : 1}.to_json}
    end
  end

  def show
    @stock = BaseStock.find(params[:id])
    if @stock.is_index?
      @guide_up = @stock.top_stocks_by_exchange("desc")
      @guide_down = @stock.top_stocks_by_exchange("asc")
    end
    @stock_screener = @stock.stock_screener
    @fund_flow = RestClient.api.stock.trading_flow.funding(@stock.id, 5) rescue {}
    @pie_chart = RestClient.api.stock.trading_flow.pie(@stock.id).in_groups_of(2).map(&:sum) rescue []
    @relate_stocks = @stock.stock_screener.competitors.where("id != ?", @stock.id).limit(4) || []
    @page_title = @stock.com_name.dup
    set_pc_link("/stocks/#{@stock.id}")
  end

  def sort_by
    params[:sort] && %w{market_value score change_rate}.include?(params[:sort][:sort_by]) ? params[:sort][:sort_by] : 'market_value'
  end
  
  def direction
    params[:sort] && %w{desc asc}.include?(params[:sort][:direction]) ? params[:sort][:direction] : 'desc'
  end
end