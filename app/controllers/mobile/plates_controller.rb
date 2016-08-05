class Mobile::PlatesController < Mobile::ApplicationController
  before_action :hide_iclick, :hide_page_title_postfix, :hide_top_bar
  
  layout "mobile/common"

  before_action :get_plate, on: %w[ show ]

  def show
    @limit_count = 30

    @page_title = @plate.name
    @stock_ids = @plate.base_stocks.ids

    @stocks = MD::RS::Stock.any_in(base_stock_id: @stock_ids).desc(:percent_change_from_previous_close)

    if @stock_ids.count > 2 * @limit_count
      before_stock = @stocks.limit(@limit_count)
      after_stock = @stocks.limit(@limit_count).offset(@stock_ids.count-@limit_count)
      @stocks = before_stock + after_stock
    end
   
    @ext_stocks = BaseStock.where(id: @stock_ids).load

    @stocks = @stocks.map do |s|
      stock = @ext_stocks.find{|bs| bs.id == s.base_stock_id }
      s.symbol = stock.symbol rescue nil
      s.c_name = stock.c_name rescue nil
      s.trading_halt = stock.trading_halt? rescue false
      if stock.trading_halt?
        s.percent_change_from_previous_close = 0
      end
      {id: s.base_stock_id, name: s.c_name, symbol: s.symbol, price: Caishuo::Utils::Helper.pretty_number(s.last, 2, false),pct: Caishuo::Utils::Helper.pretty_number(s.percent_change_from_previous_close, 2, false), closed: s.trading_halt}
    end
    @stocks = @stocks.sort{|a,b| b[:pct].to_f <=> a[:pct].to_f}
  end

  private

    def get_plate
      @plate = Plate::Base.find_by(base_stock_id: params[:id])
    end
    
end